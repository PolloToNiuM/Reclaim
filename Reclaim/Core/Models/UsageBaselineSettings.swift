import Foundation

struct UsageBaselineSettings: Equatable, Codable {
    var age: Int = 28
    var baselineDailyScreenMinutes: Int = 240
    var installedAt: Date = Date()
    var isOnboardingComplete = false
    var hasRequestedScreenTimeAuthorization = false

    var lifeExpectancy: Int {
        age >= 75 ? age + 5 : 80
    }

    var remainingLifeYears: Int {
        max(0, lifeExpectancy - age)
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 28
        baselineDailyScreenMinutes = try container.decodeIfPresent(Int.self, forKey: .baselineDailyScreenMinutes) ?? 240
        installedAt = try container.decodeIfPresent(Date.self, forKey: .installedAt) ?? Date()
        isOnboardingComplete = try container.decodeIfPresent(Bool.self, forKey: .isOnboardingComplete) ?? false
        hasRequestedScreenTimeAuthorization = try container.decodeIfPresent(Bool.self, forKey: .hasRequestedScreenTimeAuthorization) ?? false
    }
}
