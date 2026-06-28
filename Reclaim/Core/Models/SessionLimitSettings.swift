import Foundation

struct SessionLimitSettings: Equatable, Codable {
    var isEnabled = true
    var usageThresholdMinutes = 15
    var blockDurationMinutes = 5
    var requiresChallenge = true

    static let minimumUsageThresholdMinutes = 1
    static let maximumUsageThresholdMinutes = 45
    static let usageOptions = Array(minimumUsageThresholdMinutes...maximumUsageThresholdMinutes)
    static let blockOptions = Array(1...30)

    mutating func normalize() {
        usageThresholdMinutes = min(
            max(usageThresholdMinutes, Self.minimumUsageThresholdMinutes),
            Self.maximumUsageThresholdMinutes
        )
    }
}
