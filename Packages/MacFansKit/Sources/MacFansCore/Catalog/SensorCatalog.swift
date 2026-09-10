public enum SensorCatalog {
    public static func isPlausible(celsius: Double) -> Bool {
        celsius != 0 && (-40...150).contains(celsius)
    }

    public static func sensors(for keys: [String], overrides: [SensorID: SensorOverride] = [:]) -> [Sensor] {
        var numbering = SensorNamingRule.SeriesNumbering()
        let rules = SensorNamingRule.rules(for: keys)
        return keys.sorted().map { key in
            let rule = rules.first { $0.matches(key) }
            let catalogName = rule?.label.name(for: key, numbering: &numbering) ?? key
            let id = SensorID(rawValue: key)
            let override = overrides[id]
            return Sensor(
                id: id,
                name: override?.name ?? catalogName,
                group: rule?.group ?? .other,
                isFavorite: override?.isFavorite ?? false
            )
        }
    }

    public static func summaries(sensors: [Sensor], readings: [SensorID: Double]) -> [SensorSummary] {
        var members: [SensorFamily: [(id: SensorID, representsFamily: Bool)]] = [:]
        let rules = SensorNamingRule.rules(for: sensors.lazy.map(\.id.rawValue))
        for sensor in sensors {
            guard let rule = rules.first(where: { $0.matches(sensor.id.rawValue) }), let family = rule.family else { continue }
            members[family, default: []].append((sensor.id, rule.representsFamily))
        }
        return SensorFamily.allCases.compactMap { family in
            guard let familyMembers = members[family] else { return nil }
            let representatives = familyMembers.filter(\.representsFamily)
            let ids = (representatives.isEmpty ? familyMembers : representatives).map(\.id)
            let values = ids.compactMap { readings[$0] }
            guard let max = Aggregate.max.value(of: values), let average = Aggregate.average.value(of: values) else { return nil }
            return SensorSummary(family: family, max: max, average: average, sensorIDs: ids)
        }
    }
}
