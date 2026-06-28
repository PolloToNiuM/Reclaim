import DeviceActivity
import FamilyControls
import Foundation

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

struct DeviceActivityService {
    private let center = DeviceActivityCenter()

    func startSessionLimitMonitoring(
        selection: FamilyActivitySelection,
        settings: SessionLimitSettings
    ) throws {
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty else {
            throw DeviceActivityServiceError.emptySelection
        }

        guard settings.isEnabled else {
            stopSessionLimitMonitoring()
            return
        }

        let usageThresholdMinutes = max(
            min(settings.usageThresholdMinutes, SessionLimitSettings.maximumUsageThresholdMinutes),
            SessionLimitSettings.minimumUsageThresholdMinutes
        )

        try ScreenTimeSharedStore.save(selection: selection)
        ScreenTimeSharedStore.saveSessionLimitUsageThreshold(minutes: usageThresholdMinutes)
        ScreenTimeSharedStore.saveSessionLimitBlockDuration(minutes: settings.blockDurationMinutes)
        ScreenTimeSharedStore.appendDebugLog(
            "configure session limit threshold=\(usageThresholdMinutes)m block=\(settings.blockDurationMinutes)m window=24h apps=\(selection.applicationTokens.count) categories=\(selection.categoryTokens.count) domains=\(selection.webDomainTokens.count)"
        )

        center.stopMonitoring([.reclaimSessionLimit])
        ScreenTimeSharedStore.appendDebugLog("stopped previous reclaimSessionLimit before start")

        let schedule = Self.sessionLimitSchedule()

        do {
            try center.startMonitoring(
                .reclaimSessionLimit,
                during: schedule,
                events: sessionLimitEvents(
                    for: selection,
                    thresholdMinutes: usageThresholdMinutes
                )
            )
            ScreenTimeSharedStore.appendDebugLog("startMonitoring reclaimSessionLimit OK")
        } catch {
            ScreenTimeSharedStore.appendDebugLog("startMonitoring reclaimSessionLimit ERROR \(error.localizedDescription)")
            throw error
        }
    }

    func stopSessionLimitMonitoring() {
        center.stopMonitoring([.reclaimSessionLimit, .reclaimSessionBlock])
        ScreenTimeSharedStore.clearSessionLimitBlockEndDate()
        ScreenTimeSharedStore.appendDebugLog("stopSessionLimitMonitoring app called")
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

    private static func sessionLimitSchedule() -> DeviceActivitySchedule {
        return DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
    }
}

enum DeviceActivityServiceError: LocalizedError {
    case emptySelection

    var errorDescription: String? {
        switch self {
        case .emptySelection:
            "Choisis d'abord les apps à surveiller avec Screen Time."
        }
    }
}
