import Combine
import FamilyControls
import Foundation

struct MathChallenge: Equatable {
    let question: String
    let answer: Int
}

final class ReclaimViewModel: ObservableObject {
    @Published var apps: [DistractingApp] = [
        DistractingApp(name: "Instagram", category: "Social", symbol: "camera.fill", isSelected: true),
        DistractingApp(name: "TikTok", category: "Video", symbol: "music.note", isSelected: true),
        DistractingApp(name: "YouTube", category: "Video", symbol: "play.rectangle.fill", isSelected: true),
        DistractingApp(name: "X", category: "Social", symbol: "text.bubble.fill", isSelected: false),
        DistractingApp(name: "Reddit", category: "Forum", symbol: "bubble.left.and.bubble.right.fill", isSelected: false),
        DistractingApp(name: "Safari", category: "Web", symbol: "safari.fill", isSelected: false),
        DistractingApp(name: "Netflix", category: "Streaming", symbol: "tv.fill", isSelected: false),
        DistractingApp(name: "Snapchat", category: "Social", symbol: "bolt.fill", isSelected: false)
    ]

    @Published var session: FocusSession?
    @Published var stats = ReclaimStats() { didSet { saveSnapshot() } }
    @Published var now = Date()
    @Published var challenge = ReclaimViewModel.makeChallenge()
    @Published var challengeMessage = ""
    @Published var screenTimeAuthorization: ScreenTimeAuthorizationState = .notDetermined
    @Published var realSelectionStore = FamilyActivitySelectionStore()
    @Published var shieldMessage = ""
    @Published var selectedFocusMinutes = 25 { didSet { saveSnapshot() } }
    @Published var scheduledBlocks: [ScheduledBlock] = ScheduledBlock.samples { didSet { saveSnapshot() } }
    @Published var strictMode = StrictModeSettings() { didSet { saveSnapshot() } }
    @Published var sessionLimitSettings = SessionLimitSettings() { didSet { saveSnapshot() } }
    @Published var baselineSettings = UsageBaselineSettings() { didSet { saveSnapshot() } }
    @Published var deviceActivityMessage = ""
    @Published var sessionLimitSnoozeUntil: Date?

    private var timer: Timer?
    private var clockTimer: Timer?
    private let authorizationService = ScreenTimeAuthorizationService()
    private let shieldService = AppShieldService()
    private let deviceActivityService = DeviceActivityService()
    let maximumScheduledBlocks = 6

    init() {
        if let snapshot = ReclaimPersistenceStore.load() {
            stats = snapshot.stats
            selectedFocusMinutes = snapshot.selectedFocusMinutes
            scheduledBlocks = snapshot.scheduledBlocks
            strictMode = snapshot.strictMode
            sessionLimitSettings = snapshot.sessionLimitSettings
            sessionLimitSettings.normalize()
            baselineSettings = snapshot.baselineSettings
        }
        screenTimeAuthorization = authorizationService.currentState()
        startClock()
    }

    var selectedApps: [DistractingApp] {
        apps.filter(\.isSelected)
    }

    var realSelection: FamilyActivitySelection {
        get { realSelectionStore.selection }
        set {
            realSelectionStore.selection = newValue
            try? ScreenTimeSharedStore.save(selection: newValue)
        }
    }

    var hasRealSelection: Bool {
        !realSelectionStore.isEmpty
    }

    var realSelectionSummary: String {
        guard hasRealSelection else { return "Aucune sélection réelle" }
        return "\(realSelectionStore.itemCount) élément(s) sélectionné(s)"
    }

    var isRealShieldActive: Bool {
        shieldService.isShieldActive
    }

    var isSessionLimitSnoozed: Bool {
        guard let sessionLimitSnoozeUntil else { return false }
        return sessionLimitSnoozeUntil > now
    }

    var canSnoozeSessionLimit: Bool {
        sessionLimitSettings.isEnabled && !isSessionLimitSnoozed
    }

    var sessionLimitSnoozeRemainingSeconds: Int {
        guard let sessionLimitSnoozeUntil else { return 0 }
        return max(0, Int(sessionLimitSnoozeUntil.timeIntervalSince(now)))
    }

    var sessionState: FocusSessionState {
        session?.state ?? .inactive
    }

    var isSessionActive: Bool {
        session != nil
    }

    var remainingSeconds: Int {
        guard let session else { return 0 }
        return max(0, Int(session.endsAt.timeIntervalSince(now)))
    }

    var progress: Double {
        guard let session else { return 0 }
        let elapsed = now.timeIntervalSince(session.startedAt)
        return min(max(elapsed / session.duration, 0), 1)
    }

    var focusSecondsToday: Int {
        stats.protectedSecondsToday + currentSessionSeconds
    }

    var protectedMinutes: Int {
        max(0, focusSecondsToday / 60)
    }

    var recoveredMinutes: Int {
        protectedMinutes
    }

    var baselineScreenMinutesNow: Int {
        Int(Double(baselineSettings.baselineDailyScreenMinutes) * dayProgress)
    }

    var dayProgressFraction: Double {
        dayProgress
    }

    var canEstimateScreenTime: Bool {
        screenTimeAuthorization.isAuthorized
    }

    var hasReclaimScreenTimeData: Bool {
        hasRealSelection && (stats.sessions > 0 || stats.triggeredBlocks > 0 || recoveredMinutes > 0)
    }

    var canShowReclaimScreenTime: Bool {
        canEstimateScreenTime && hasReclaimScreenTimeData
    }

    var estimatedScreenMinutesToday: Int {
        hasReclaimScreenTimeData ? recoveredMinutes : 0
    }

    var estimatedSavedMinutesToday: Int {
        recoveredMinutes
    }

    var projectedLifetimePhoneYears: Double {
        let remainingMinutes = Double(baselineSettings.remainingLifeYears * 365 * baselineSettings.baselineDailyScreenMinutes)
        return remainingMinutes / 525_600
    }

    var reclaimedLifeYears: Double {
        Double(recoveredMinutes) / 525_600
    }

    var nextScheduledBlocksToday: [ScheduledBlock] {
        let weekday = Weekday(date: now)
        let calendar = Calendar.current
        return scheduledBlocks
            .filter { block in
                block.days.contains(weekday) && calendar.dateComponents([.hour, .minute], from: block.start).minutesOfDay >= calendar.dateComponents([.hour, .minute], from: now).minutesOfDay
            }
            .sorted { first, second in
                calendar.dateComponents([.hour, .minute], from: first.start).minutesOfDay < calendar.dateComponents([.hour, .minute], from: second.start).minutesOfDay
            }
    }

    var mascotState: ReclaimMascotState {
        switch sessionState {
        case .inactive:
            return stats.successfulChallenges > 0 ? .success : .idle
        case .active:
            return isRealShieldActive ? .blocked : .focus
        case .temporaryUnlock:
            return .temporaryUnlock
        }
    }

    var activeBlockTitle: String {
        switch sessionState {
        case .inactive:
            if isSessionLimitSnoozed { return "Blocage scroll en pause" }
            return sessionLimitSettings.isEnabled ? "Blocage scroll actif" : "Blocage scroll inactif"
        case .active:
            return isRealShieldActive ? "Blocage immédiat actif" : "Screen Time à configurer"
        case .temporaryUnlock:
            return "Pause temporaire active"
        }
    }

    private var currentSessionSeconds: Int {
        guard let session else { return 0 }
        return max(0, Int(min(now.timeIntervalSince(session.startedAt), session.duration)))
    }

    private var dayProgress: Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let minutes = Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
        return min(max(minutes / 1_440, 0), 1)
    }

    func toggleApp(_ app: DistractingApp) {
        guard let index = apps.firstIndex(of: app) else { return }
        apps[index].isSelected.toggle()
    }

    func requestScreenTimeAuthorization() async {
        baselineSettings.hasRequestedScreenTimeAuthorization = true
        screenTimeAuthorization = await authorizationService.requestAuthorization()
        if case let .failed(message) = screenTimeAuthorization {
            shieldMessage = "Autorisation impossible: \(message)"
        } else {
            shieldMessage = ""
        }
    }

    @discardableResult
    func startFocus(duration: TimeInterval = 25 * 60) -> Bool {
        shieldMessage = ""

        guard screenTimeAuthorization.isAuthorized else {
            shieldMessage = "Reclaim a besoin des permissions Screen Time pour bloquer tes apps."
            return false
        }

        guard hasRealSelection else {
            shieldMessage = "Choisis d'abord les apps à bloquer dans l'onglet Apps."
            return false
        }

        shieldService.applyShield(selection: realSelection)
        shieldMessage = "Blocage réel actif via Screen Time."
        session = FocusSession(startedAt: Date(), duration: duration)
        stats.sessions += 1
        stats.triggeredBlocks += 1
        startTimer()
        return true
    }

    @discardableResult
    func startFocusWithSelectedDuration() -> Bool {
        startFocus(duration: TimeInterval(selectedFocusMinutes * 60))
    }

    func endFocus() {
        stats.protectedSecondsToday = focusSecondsToday
        shieldService.clearShield()
        shieldMessage = ""
        session = nil
        timer?.invalidate()
        timer = nil
    }

    func registerUnlockAttempt() {
        stats.unlockAttempts += 1
        challenge = Self.makeChallenge(difficulty: strictMode.challengeDifficulty)
        challengeMessage = ""
    }

    func prepareSettingsChallenge() {
        challenge = Self.makeChallenge(difficulty: strictMode.challengeDifficulty)
        challengeMessage = ""
    }

    func prepareSessionLimitSnoozeChallenge() {
        challenge = Self.makeChallenge(difficulty: strictMode.challengeDifficulty)
        challengeMessage = ""
    }

    func validateChallengeOnly(_ text: String) -> Bool {
        guard Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) == challenge.answer else {
            challengeMessage = "Pas encore. Reessaie calmement."
            return false
        }

        stats.successfulChallenges += 1
        challengeMessage = "Challenge valide."
        return true
    }

    func grantPauseWithoutChallenge() {
        stats.unlockAttempts += 1
        grantTemporaryUnlock()
    }

    func canRequestPause() -> Bool {
        strictMode.allowsPauses
    }

    func configureSessionLimitMonitoring() {
        deviceActivityMessage = ""

        if reconcileSessionLimitBlockState() {
            return
        }

        guard !isSessionLimitSnoozed else {
            deviceActivityMessage = "Blocage scroll en pause encore \(formattedTime(sessionLimitSnoozeRemainingSeconds))."
            return
        }

        guard screenTimeAuthorization.isAuthorized else {
            deviceActivityMessage = "Autorise Screen Time avant d'activer la limite de session."
            return
        }

        do {
            try deviceActivityService.startSessionLimitMonitoring(
                selection: realSelection,
                settings: sessionLimitSettings
            )
            deviceActivityMessage = sessionLimitSettings.isEnabled
                ? "Limite de session activée via DeviceActivity."
                : "Limite de session désactivée."
        } catch {
            deviceActivityMessage = error.localizedDescription
        }
    }

    func stopSessionLimitMonitoring() {
        deviceActivityService.stopSessionLimitMonitoring()
        shieldService.clearShield()
        ScreenTimeSharedStore.clearSessionLimitBlockEndDate()
        deviceActivityMessage = "Limite de session arrêtée."
    }

    @discardableResult
    func reconcileSessionLimitBlockState() -> Bool {
        guard let blockEndDate = ScreenTimeSharedStore.loadSessionLimitBlockEndDate() else {
            return false
        }

        let remainingSeconds = Int(blockEndDate.timeIntervalSince(Date()))
        guard remainingSeconds <= 0 else {
            deviceActivityMessage = "Blocage scroll actif encore \(formattedTime(remainingSeconds))."
            return true
        }

        shieldService.clearShield()
        ScreenTimeSharedStore.clearSessionLimitBlockEndDate()
        ScreenTimeSharedStore.appendDebugLog("reconciled expired session block, cleared shield before rearm")
        deviceActivityMessage = "Blocage terminé, réarmement en cours."
        return false
    }

    func snoozeSessionLimit(answer text: String) -> Bool {
        guard validateChallengeOnly(text) else { return false }
        snoozeSessionLimitForFiveMinutes()
        challengeMessage = "Bien joue. Blocage scroll en pause pour 5 minutes."
        return true
    }

    func endSessionLimitSnooze() {
        sessionLimitSnoozeUntil = nil
        if sessionLimitSettings.isEnabled {
            configureSessionLimitMonitoring()
        }
    }

    func submitChallengeAnswer(_ text: String) -> Bool {
        guard Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) == challenge.answer else {
            challengeMessage = "Pas encore. Respire, puis réessaie calmement."
            return false
        }

        grantTemporaryUnlock()
        return true
    }

    func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func completeBaselineOnboarding(age: Int, dailyScreenMinutes: Int) {
        baselineSettings.age = min(max(age, 13), 100)
        baselineSettings.baselineDailyScreenMinutes = min(max(dailyScreenMinutes, 15), 1_200)
        sessionLimitSettings.isEnabled = true
        baselineSettings.isOnboardingComplete = true
        configureSessionLimitMonitoring()
    }

    func upsertScheduledBlock(_ block: ScheduledBlock) {
        if let index = scheduledBlocks.firstIndex(where: { $0.id == block.id }) {
            scheduledBlocks[index] = block
        } else if scheduledBlocks.count < maximumScheduledBlocks {
            scheduledBlocks.append(block)
        }
    }

    func deleteScheduledBlock(_ block: ScheduledBlock) {
        scheduledBlocks.removeAll { $0.id == block.id }
    }

    private func startTimer() {
        timer?.invalidate()
        now = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func startClock() {
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.now = Date()
        }
    }

    private func tick() {
        now = Date()

        if case let .temporaryUnlock(until)? = session?.state, now >= until {
            session?.state = .active
            reapplyShieldIfPossible()
        }

        if let sessionLimitSnoozeUntil, now >= sessionLimitSnoozeUntil {
            self.sessionLimitSnoozeUntil = nil
            if sessionLimitSettings.isEnabled {
                configureSessionLimitMonitoring()
            }
        }

        if remainingSeconds == 0, session != nil {
            endFocus()
        }
    }

    private func grantTemporaryUnlock() {
        stats.successfulChallenges += 1
        shieldService.clearShield()
        session?.state = .temporaryUnlock(until: Date().addingTimeInterval(5 * 60))
        shieldMessage = "Accès temporaire accordé. Reviens à ton intention ensuite."
        challengeMessage = "Bien joué. Accès temporaire débloqué pour 5 minutes."
    }

    private func snoozeSessionLimitForFiveMinutes() {
        let until = Date().addingTimeInterval(5 * 60)
        sessionLimitSnoozeUntil = until
        deviceActivityService.stopSessionLimitMonitoring()
        deviceActivityMessage = "Blocage scroll en pause pour 5 minutes."

        DispatchQueue.main.asyncAfter(deadline: .now() + 5 * 60) { [weak self] in
            guard let self, self.sessionLimitSnoozeUntil == until else { return }
            self.sessionLimitSnoozeUntil = nil
            if self.sessionLimitSettings.isEnabled {
                self.configureSessionLimitMonitoring()
            }
        }
    }

    private func reapplyShieldIfPossible() {
        guard screenTimeAuthorization.isAuthorized, hasRealSelection, session != nil else { return }
        shieldService.applyShield(selection: realSelection)
        shieldMessage = "Blocage réappliqué après la pause."
    }

    private func saveSnapshot() {
        ReclaimPersistenceStore.save(
            ReclaimPersistenceSnapshot(
                stats: stats,
                selectedFocusMinutes: selectedFocusMinutes,
                scheduledBlocks: scheduledBlocks,
                strictMode: strictMode,
                sessionLimitSettings: sessionLimitSettings,
                baselineSettings: baselineSettings
            )
        )
    }

    private static func makeChallenge() -> MathChallenge {
        makeChallenge(difficulty: .medium)
    }

    private static func makeChallenge(difficulty: ChallengeDifficulty) -> MathChallenge {
        let leftRange: ClosedRange<Int>
        let rightRange: ClosedRange<Int>
        let bonusRange: ClosedRange<Int>

        switch difficulty {
        case .easy:
            leftRange = 6...14
            rightRange = 4...12
            bonusRange = 2...12
        case .medium:
            leftRange = 12...28
            rightRange = 11...24
            bonusRange = 7...31
        case .hard:
            leftRange = 22...49
            rightRange = 13...36
            bonusRange = 17...79
        }

        let left = Int.random(in: leftRange)
        let right = Int.random(in: rightRange)
        let bonus = Int.random(in: bonusRange)
        return MathChallenge(question: "\(left) x \(right) + \(bonus)", answer: left * right + bonus)
    }
}

private extension Weekday {
    init(date: Date) {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: self = .sunday
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        default: self = .saturday
        }
    }
}

private extension ScheduledBlock {
    static var samples: [ScheduledBlock] {
        [
            ScheduledBlock(
                name: "Deconnexion du soir",
                start: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date(),
                end: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date(),
                days: [.monday, .tuesday, .wednesday, .thursday, .friday],
                usesStrictMode: true
            )
        ]
    }
}
