import Foundation
import os

let log = Logger(subsystem: "com.jasperkang.macfans", category: "Helper")

let writer: FanWriter
do {
    writer = try FanWriter()
} catch {
    log.fault("SMC unavailable: \(error.localizedDescription)")
    exit(1)
}

let watchdog = Watchdog(writer: writer)
let listenerDelegate = HelperListener(service: HelperService(writer: writer, watchdog: watchdog))
let listener = NSXPCListener(machServiceName: helperMachServiceName)
listener.delegate = listenerDelegate
listener.resume()

signal(SIGTERM, SIG_IGN)
let termination = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
termination.setEventHandler {
    try? writer.setAllAuto()
    exit(0)
}
termination.resume()

log.info("Listening on \(helperMachServiceName)")
dispatchMain()
