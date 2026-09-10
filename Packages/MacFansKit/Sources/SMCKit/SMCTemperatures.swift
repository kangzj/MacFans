extension SMCConnection {
    public func temperatureKeys() throws -> [SMCKey] {
        if let cached = lock.withLock({ temperatureKeyCache }) { return cached }
        let keys = try allKeys()
            .filter { $0.hasPrefix("T") && isTemperatureType($0) }
            .sorted()
        lock.withLock { temperatureKeyCache = keys }
        return keys
    }

    public func temperatures(_ keys: [SMCKey]) -> [SMCKey: Double] {
        keys.reduce(into: [:]) { readings, key in
            if let value = try? readDouble(key) { readings[key] = value }
        }
    }

    private func isTemperatureType(_ key: SMCKey) -> Bool {
        guard let type = try? keyInfo(key).dataType else { return false }
        return type == .flt || type == .sp78
    }
}
