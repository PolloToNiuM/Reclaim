import FamilyControls
import Foundation

enum ScreenTimeSharedStore {
    static let appGroupIdentifier = "group.com.example.Reclaim"
    private static let selectionKey = "reclaim.familyActivitySelection"
    private static let sessionLimitUsageThresholdKey = "reclaim.sessionLimit.usageThresholdMinutes"
    private static let sessionLimitBlockDurationKey = "reclaim.sessionLimit.blockDurationMinutes"
    private static let sessionLimitResetWindowKey = "reclaim.sessionLimit.resetWindowSeconds"
    private static let sessionLimitBlockEndDateKey = "reclaim.sessionLimit.blockEndDate"
    private static let debugLogKey = "reclaim.screenTime.debugLog"
    private static let maximumDebugLogLines = 120

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static func save(selection: FamilyActivitySelection) throws {
        let data = try JSONEncoder().encode(selection)
        userDefaults.set(data, forKey: selectionKey)
    }

    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = userDefaults.data(forKey: selectionKey) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    static func saveSessionLimitBlockDuration(minutes: Int) {
        userDefaults.set(minutes, forKey: sessionLimitBlockDurationKey)
    }

    static func saveSessionLimitUsageThreshold(minutes: Int) {
        userDefaults.set(minutes, forKey: sessionLimitUsageThresholdKey)
    }

    static func saveSessionLimitResetWindow(seconds: Int) {
        userDefaults.set(seconds, forKey: sessionLimitResetWindowKey)
    }

    static func saveSessionLimitBlockEndDate(_ date: Date) {
        userDefaults.set(date.timeIntervalSince1970, forKey: sessionLimitBlockEndDateKey)
    }

    static func loadSessionLimitBlockEndDate() -> Date? {
        let timestamp = userDefaults.double(forKey: sessionLimitBlockEndDateKey)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    static func clearSessionLimitBlockEndDate() {
        userDefaults.removeObject(forKey: sessionLimitBlockEndDateKey)
    }

    static func appendDebugLog(_ message: String) {
        var lines = userDefaults.stringArray(forKey: debugLogKey) ?? []
        lines.append("\(debugTimestamp()) app: \(message)")
        if lines.count > maximumDebugLogLines {
            lines = Array(lines.suffix(maximumDebugLogLines))
        }
        userDefaults.set(lines, forKey: debugLogKey)
    }

    static func loadDebugLogText() -> String {
        (userDefaults.stringArray(forKey: debugLogKey) ?? []).joined(separator: "\n")
    }

    static func clearDebugLog() {
        userDefaults.removeObject(forKey: debugLogKey)
    }

    private static func debugTimestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
