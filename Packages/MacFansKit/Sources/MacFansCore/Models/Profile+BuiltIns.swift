import Foundation

extension Profile {
    public static let quiet = Profile(
        id: UUID(uuidString: "6B1F4B4E-0C3A-4E1E-9C4B-2A4D7B1E5A01")!,
        name: "Quiet",
        rules: [
            Rule(name: "CPU hot", trigger: .group(.cpu, .max), onAbove: 90, offBelow: 80, speed: .percent(60)),
            Rule(name: "GPU hot", trigger: .group(.gpu, .max), onAbove: 90, offBelow: 80, speed: .percent(60)),
        ],
        isBuiltIn: true
    )

    public static let balanced = Profile(
        id: UUID(uuidString: "6B1F4B4E-0C3A-4E1E-9C4B-2A4D7B1E5A02")!,
        name: "Balanced",
        rules: [
            Rule(name: "CPU warm", trigger: .group(.cpu, .max), onAbove: 75, offBelow: 65, speed: .percent(50)),
            Rule(name: "CPU hot", trigger: .group(.cpu, .max), onAbove: 90, offBelow: 80, speed: .max),
            Rule(name: "GPU warm", trigger: .group(.gpu, .max), onAbove: 80, offBelow: 70, speed: .percent(60)),
        ],
        isBuiltIn: true
    )

    public static let cool = Profile(
        id: UUID(uuidString: "6B1F4B4E-0C3A-4E1E-9C4B-2A4D7B1E5A03")!,
        name: "Cool",
        rules: [
            Rule(name: "CPU warm", trigger: .group(.cpu, .max), onAbove: 60, offBelow: 50, speed: .percent(40)),
            Rule(name: "CPU hot", trigger: .group(.cpu, .max), onAbove: 75, offBelow: 65, speed: .percent(70)),
            Rule(name: "GPU warm", trigger: .group(.gpu, .max), onAbove: 65, offBelow: 55, speed: .percent(70)),
            Rule(name: "SoC critical", trigger: .group(.soc, .max), onAbove: 95, offBelow: 85, speed: .max),
        ],
        isBuiltIn: true
    )

    public static let builtIns: [Profile] = [quiet, balanced, cool]
}
