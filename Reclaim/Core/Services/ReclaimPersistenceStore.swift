import Foundation

struct ReclaimPersistenceSnapshot: Codable {
    var stats: ReclaimStats
    var selectedFocusMinutes: Int
    var scheduledBlocks: [ScheduledBlock]
    var strictMode: StrictModeSettings
    var sessionLimitSettings: SessionLimitSettings
    var baselineSettings: UsageBaselineSettings

    init(
        stats: ReclaimStats,
        selectedFocusMinutes: Int,
        scheduledBlocks: [ScheduledBlock],
        strictMode: StrictModeSettings,
        sessionLimitSettings: SessionLimitSettings,
        baselineSettings: UsageBaselineSettings
    ) {
        self.stats = stats
        self.selectedFocusMinutes = selectedFocusMinutes
        self.scheduledBlocks = scheduledBlocks
        self.strictMode = strictMode
        self.sessionLimitSettings = sessionLimitSettings
        self.baselineSettings = baselineSettings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stats = try container.decode(ReclaimStats.self, forKey: .stats)
        selectedFocusMinutes = try container.decode(Int.self, forKey: .selectedFocusMinutes)
        scheduledBlocks = try container.decode([ScheduledBlock].self, forKey: .scheduledBlocks)
        strictMode = try container.decode(StrictModeSettings.self, forKey: .strictMode)
        sessionLimitSettings = try container.decode(SessionLimitSettings.self, forKey: .sessionLimitSettings)
        baselineSettings = try container.decodeIfPresent(UsageBaselineSettings.self, forKey: .baselineSettings) ?? UsageBaselineSettings()
    }
}

enum ReclaimPersistenceStore {
    private static let key = "reclaim.v4.persistence"

    static func load() -> ReclaimPersistenceSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ReclaimPersistenceSnapshot.self, from: data)
    }

    static func save(_ snapshot: ReclaimPersistenceSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
