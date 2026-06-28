import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

extension DeviceActivityName {
    static let reclaimSessionLimit = Self("reclaim.sessionLimit")
    static let reclaimSessionBlock = Self("reclaim.sessionBlock")
    static let reclaimScheduledBlock = Self("reclaim.scheduledBlock")
}

extension DeviceActivityEvent.Name {
    static let reclaimSessionWarmupCategoryThreshold = Self("reclaim.session.warmup.category")
    static let reclaimSessionThreshold = Self("reclaim.sessionThreshold")
    static let reclaimSessionCategoryThreshold = Self("reclaim.session.category")

    static func reclaimSessionWarmupApplicationThreshold(index: Int) -> Self {
        Self("reclaim.session.warmup.app.\(index)")
    }

    static func reclaimSessionWarmupWebDomainThreshold(index: Int) -> Self {
        Self("reclaim.session.warmup.web.\(index)")
    }

    static func reclaimSessionApplicationThreshold(index: Int) -> Self {
        Self("reclaim.session.app.\(index)")
    }

    static func reclaimSessionWebDomainThreshold(index: Int) -> Self {
        Self("reclaim.session.web.\(index)")
    }
}

private enum ExtensionSharedStore {
    static let appGroupIdentifier = "group.com.example.Reclaim"
    private static let selectionKey = "reclaim.familyActivitySelection"
    private static let sessionLimitUsageThresholdKey = "reclaim.sessionLimit.usageThresholdMinutes"
    private static let sessionLimitBlockDurationKey = "reclaim.sessionLimit.blockDurationMinutes"
    private static let sessionLimitResetWindowKey = "reclaim.sessionLimit.resetWindowSeconds"
    private static let sessionLimitWarmupDateKey = "reclaim.sessionLimit.warmupDate"
    private static let sessionLimitBlockEndDateKey = "reclaim.sessionLimit.blockEndDate"
    private static let debugLogKey = "reclaim.screenTime.debugLog"
    private static let maximumDebugLogLines = 120

    static func loadSelection() -> FamilyActivitySelection? {
        guard
            let defaults = UserDefaults(suiteName: appGroupIdentifier),
            let data = defaults.data(forKey: selectionKey)
        else {
            return nil
        }

        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    static func loadSessionLimitBlockDurationMinutes() -> Int {
        let value = UserDefaults(suiteName: appGroupIdentifier)?
            .integer(forKey: sessionLimitBlockDurationKey) ?? 0
        return value > 0 ? value : 5
    }

    static func loadSessionLimitUsageThresholdMinutes() -> Int {
        let value = UserDefaults(suiteName: appGroupIdentifier)?
            .integer(forKey: sessionLimitUsageThresholdKey) ?? 0
        return min(max(value > 0 ? value : 15, 1), 45)
    }

    static func loadSessionLimitResetWindowSeconds() -> Int {
        let value = UserDefaults(suiteName: appGroupIdentifier)?
            .integer(forKey: sessionLimitResetWindowKey) ?? 0
        return value > 0 ? value : 24 * 60 * 60
    }

    static func saveSessionLimitWarmupDate(_ date: Date) {
        UserDefaults(suiteName: appGroupIdentifier)?.set(date.timeIntervalSince1970, forKey: sessionLimitWarmupDateKey)
    }

    static func loadSessionLimitWarmupDate() -> Date? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        let timestamp = defaults.double(forKey: sessionLimitWarmupDateKey)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    static func clearSessionLimitWarmupDate() {
        UserDefaults(suiteName: appGroupIdentifier)?.removeObject(forKey: sessionLimitWarmupDateKey)
    }

    static func saveSessionLimitBlockEndDate(_ date: Date) {
        UserDefaults(suiteName: appGroupIdentifier)?.set(date.timeIntervalSince1970, forKey: sessionLimitBlockEndDateKey)
    }

    static func clearSessionLimitBlockEndDate() {
        UserDefaults(suiteName: appGroupIdentifier)?.removeObject(forKey: sessionLimitBlockEndDateKey)
    }

    static func appendDebugLog(_ message: String) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        var lines = defaults.stringArray(forKey: debugLogKey) ?? []
        lines.append("\(ISO8601DateFormatter().string(from: Date())) extension: \(message)")
        if lines.count > maximumDebugLogLines {
            lines = Array(lines.suffix(maximumDebugLogLines))
        }
        defaults.set(lines, forKey: debugLogKey)
    }
}

@objc(ReclaimDeviceActivityMonitor)
final class ReclaimDeviceActivityMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()

    override func intervalDidStart(for activity: DeviceActivityName) {
        ExtensionSharedStore.appendDebugLog("intervalDidStart activity=\(String(describing: activity))")
        guard activity == .reclaimScheduledBlock else { return }
        applyStoredShield()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        ExtensionSharedStore.appendDebugLog("intervalDidEnd activity=\(String(describing: activity))")
        switch activity {
        case .reclaimScheduledBlock:
            clearShield()
        case .reclaimSessionLimit:
            center.stopMonitoring([.reclaimSessionLimit])
            ExtensionSharedStore.appendDebugLog("stopped reclaimSessionLimit after interval end")
            restartSessionLimitMonitoring()
        case .reclaimSessionBlock:
            clearShield()
            center.stopMonitoring([.reclaimSessionBlock])
            ExtensionSharedStore.appendDebugLog("session block ended, stopped block monitor")
            restartSessionLimitMonitoring()
        default:
            break
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        ExtensionSharedStore.appendDebugLog("eventDidReachThreshold event=\(String(describing: event)) activity=\(String(describing: activity))")
        guard activity == .reclaimSessionLimit else { return }

        if isSessionWarmupEvent(event) {
            ExtensionSharedStore.saveSessionLimitWarmupDate(Date())
            ExtensionSharedStore.appendDebugLog("warmup 10s reached, probable session start saved")
            return
        }

        let thresholdMinutes = ExtensionSharedStore.loadSessionLimitUsageThresholdMinutes()
        guard shouldBlockForContinuousSession(thresholdMinutes: thresholdMinutes) else {
            ExtensionSharedStore.appendDebugLog("threshold reached but skipped: not continuous enough")
            restartSessionLimitMonitoring()
            return
        }

        center.stopMonitoring([.reclaimSessionLimit])
        ExtensionSharedStore.appendDebugLog("threshold reached and continuous, stopped reclaimSessionLimit and applying shield")
        applyStoredShield()
        startSessionBlockWindow()
        clearShieldAfterSessionLimitDurationFallback()
    }

    private func applyStoredShield() {
        guard let selection = ExtensionSharedStore.loadSelection() else {
            ExtensionSharedStore.appendDebugLog("applyStoredShield skipped: no selection")
            return
        }
        ExtensionSharedStore.appendDebugLog(
            "applyStoredShield apps=\(selection.applicationTokens.count) categories=\(selection.categoryTokens.count) domains=\(selection.webDomainTokens.count)"
        )
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
    }

    private func clearShield() {
        ExtensionSharedStore.appendDebugLog("clearShield")
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        ExtensionSharedStore.clearSessionLimitBlockEndDate()
    }

    private func startSessionBlockWindow() {
        let calendar = Calendar.current
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(ExtensionSharedStore.loadSessionLimitBlockDurationMinutes() * 60))
        ExtensionSharedStore.saveSessionLimitBlockEndDate(end)
        ExtensionSharedStore.appendDebugLog("saved session block end date duration=\(ExtensionSharedStore.loadSessionLimitBlockDurationMinutes())m")

        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: calendar.dateComponents([.hour, .minute, .second], from: end),
            repeats: false
        )

        do {
            try center.startMonitoring(.reclaimSessionBlock, during: schedule)
            ExtensionSharedStore.appendDebugLog("startMonitoring reclaimSessionBlock OK duration=\(ExtensionSharedStore.loadSessionLimitBlockDurationMinutes())m")
        } catch {
            ExtensionSharedStore.appendDebugLog("startMonitoring reclaimSessionBlock ERROR \(error.localizedDescription)")
        }
    }

    private func clearShieldAfterSessionLimitDurationFallback() {
        let duration = TimeInterval(ExtensionSharedStore.loadSessionLimitBlockDurationMinutes() * 60)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            ExtensionSharedStore.appendDebugLog("fallback clearShieldAfterSessionLimitDuration fired")
            self?.clearShield()
            self?.center.stopMonitoring([.reclaimSessionBlock])
            self?.restartSessionLimitMonitoring()
        }
    }

    private func restartSessionLimitMonitoring() {
        guard let selection = ExtensionSharedStore.loadSelection() else {
            ExtensionSharedStore.appendDebugLog("restartSessionLimitMonitoring skipped: no selection")
            return
        }

        center.stopMonitoring([.reclaimSessionLimit])
        ExtensionSharedStore.appendDebugLog("restartSessionLimitMonitoring stopped old monitor")

        let schedule = sessionLimitSchedule()
        let threshold = ExtensionSharedStore.loadSessionLimitUsageThresholdMinutes()
        ExtensionSharedStore.appendDebugLog(
            "restartSessionLimitMonitoring attempt threshold=\(threshold)m window=24h apps=\(selection.applicationTokens.count) categories=\(selection.categoryTokens.count) domains=\(selection.webDomainTokens.count)"
        )

        do {
            try center.startMonitoring(
                .reclaimSessionLimit,
                during: schedule,
                events: sessionLimitEvents(
                    for: selection,
                    thresholdMinutes: threshold
                )
            )
            ExtensionSharedStore.appendDebugLog("restartSessionLimitMonitoring OK")
        } catch {
            ExtensionSharedStore.appendDebugLog("restartSessionLimitMonitoring ERROR \(error.localizedDescription)")
        }
    }

    private func sessionLimitSchedule() -> DeviceActivitySchedule {
        return DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
    }

    private func sessionLimitEvents(
        for selection: FamilyActivitySelection,
        thresholdMinutes: Int
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        let threshold = DateComponents(minute: thresholdMinutes)
        let warmupThreshold = DateComponents(second: 10)
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for (index, token) in Array(selection.applicationTokens).enumerated() {
            events[.reclaimSessionWarmupApplicationThreshold(index: index)] = DeviceActivityEvent(
                applications: [token],
                threshold: warmupThreshold
            )
            events[.reclaimSessionApplicationThreshold(index: index)] = DeviceActivityEvent(
                applications: [token],
                threshold: threshold
            )
        }

        for (index, token) in Array(selection.webDomainTokens).enumerated() {
            events[.reclaimSessionWarmupWebDomainThreshold(index: index)] = DeviceActivityEvent(
                webDomains: [token],
                threshold: warmupThreshold
            )
            events[.reclaimSessionWebDomainThreshold(index: index)] = DeviceActivityEvent(
                webDomains: [token],
                threshold: threshold
            )
        }

        if !selection.categoryTokens.isEmpty {
            events[.reclaimSessionWarmupCategoryThreshold] = DeviceActivityEvent(
                categories: selection.categoryTokens,
                threshold: warmupThreshold
            )
            events[.reclaimSessionCategoryThreshold] = DeviceActivityEvent(
                categories: selection.categoryTokens,
                threshold: threshold
            )
        }

        return events
    }

    private func isSessionWarmupEvent(_ event: DeviceActivityEvent.Name) -> Bool {
        let description = String(describing: event)
        return description.contains("reclaim.session.warmup.")
    }

    private func shouldBlockForContinuousSession(thresholdMinutes: Int) -> Bool {
        guard let warmupDate = ExtensionSharedStore.loadSessionLimitWarmupDate() else {
            ExtensionSharedStore.appendDebugLog("continuous check: no warmup date, allow block")
            return true
        }

        let elapsed = Date().timeIntervalSince(warmupDate)
        let expected = TimeInterval(max(thresholdMinutes * 60 - 10, 0))
        let tolerance: TimeInterval = 120
        let isContinuous = elapsed <= expected + tolerance

        ExtensionSharedStore.appendDebugLog(
            "continuous check elapsed=\(Int(elapsed))s expectedAfterWarmup=\(Int(expected))s tolerance=\(Int(tolerance))s result=\(isContinuous ? "block" : "skip")"
        )

        if !isContinuous {
            ExtensionSharedStore.clearSessionLimitWarmupDate()
        }

        return isContinuous
    }
}
