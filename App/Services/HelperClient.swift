import Foundation
import Observation
import ServiceManagement
import Synchronization

@MainActor
@Observable
final class HelperClient: FanCommandSink {
    enum Status: Equatable {
        case notRegistered
        case requiresApproval
        case enabled
        case notFound
    }

    enum ClientError: LocalizedError {
        case helperNotEnabled
        case timedOut
        case remote(String)
        case transport(String)

        var errorDescription: String? {
            switch self {
            case .helperNotEnabled: "The fan control helper is not installed."
            case .timedOut: "The fan control helper did not respond."
            case .remote(let message), .transport(let message): message
            }
        }
    }

    static let callTimeout: Duration = .seconds(3)

    private(set) var status: Status = .notRegistered
    private let service = SMAppService.daemon(plistName: "\(helperMachServiceName).plist")
    private var connection: NSXPCConnection?

    init() {
        refreshStatus()
    }

    var isEnabled: Bool { status == .enabled }

    func refreshStatus() {
        status = switch service.status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .notFound
        default: .notRegistered
        }
    }

    func register() throws {
        try service.register()
        refreshStatus()
        if status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    func unregister() async throws {
        try await service.unregister()
        invalidateConnection()
        refreshStatus()
    }

    func setFan(index: Int, rpm: Double) async throws {
        try await callExpectingNoError { proxy, reply in proxy.setFan(index: index, rpm: rpm, reply: reply) }
    }

    func setAuto(index: Int) async throws {
        try await callExpectingNoError { proxy, reply in proxy.setAuto(index: index, reply: reply) }
    }

    func setAllAuto() async throws {
        try await callExpectingNoError { proxy, reply in proxy.setAllAuto(reply: reply) }
    }

    func heartbeat() async throws -> Bool {
        try await call { proxy, reply in proxy.heartbeat(reply: reply) }
    }

    func version() async throws -> Int {
        try await call { proxy, reply in proxy.version(reply: reply) }
    }

    private func callExpectingNoError(
        _ invoke: (MacFansHelperProtocol, @escaping @Sendable (String?) -> Void) -> Void
    ) async throws {
        if let message: String = try await call(invoke) {
            throw ClientError.remote(message)
        }
    }

    private func call<Reply: Sendable>(
        _ invoke: (MacFansHelperProtocol, @escaping @Sendable (Reply) -> Void) -> Void
    ) async throws -> Reply {
        guard isEnabled else { throw ClientError.helperNotEnabled }
        let connection = activeConnection()
        let settled = Mutex(false)
        let timeout = Mutex<Task<Void, Never>?>(nil)
        return try await withCheckedThrowingContinuation { continuation in
            @Sendable func settle(_ result: Result<Reply, any Error>) {
                let first = settled.withLock { alreadySettled in
                    defer { alreadySettled = true }
                    return !alreadySettled
                }
                guard first else { return }
                timeout.withLock { $0?.cancel() }
                continuation.resume(with: result)
            }
            let proxy = connection.remoteObjectProxyWithErrorHandler { error in
                settle(.failure(ClientError.transport(error.localizedDescription)))
            } as! MacFansHelperProtocol
            invoke(proxy) { reply in settle(.success(reply)) }
            timeout.withLock {
                $0 = Task {
                    guard (try? await Task.sleep(for: Self.callTimeout)) != nil else { return }
                    settle(.failure(ClientError.timedOut))
                }
            }
        }
    }

    private func activeConnection() -> NSXPCConnection {
        if let connection { return connection }
        let connection = NSXPCConnection(machServiceName: helperMachServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: MacFansHelperProtocol.self)
        connection.invalidationHandler = { [weak self] in
            Task { @MainActor in self?.connection = nil }
        }
        connection.resume()
        self.connection = connection
        return connection
    }

    private func invalidateConnection() {
        connection?.invalidate()
        connection = nil
    }
}
