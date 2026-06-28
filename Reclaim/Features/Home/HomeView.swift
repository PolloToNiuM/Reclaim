import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel
    @State private var isChallengePresented = false
    @State private var isSnoozeChallengePresented = false
    let startFocus: () -> Void

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ReclaimScreenHeader(title: "Aujourd'hui", subtitle: todaySubtitle)

                    hero
                    currentBlockCard
                    dayScreenTimeCard
                    nextBlocksCard

                    if !viewModel.screenTimeAuthorization.isAuthorized {
                        ScreenTimePermissionView()
                    }
                }
                .padding(20)
                .padding(.bottom, 18)
            }
        }
        .sheet(isPresented: $isChallengePresented) {
            NavigationStack {
                MathChallengeView()
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isSnoozeChallengePresented) {
            NavigationStack {
                MathChallengeView(
                    title: "Snooze 5 min",
                    subtitle: "Résous l'équation pour mettre le blocage scroll en pause pendant 5 minutes.",
                    successButtonTitle: "Revenir à l'accueil"
                ) { answer in
                    viewModel.snoozeSessionLimit(answer: answer)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var todaySubtitle: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private var hero: some View {
        ReclaimCard(padding: 0, cornerRadius: 34) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [
                        ReclaimColors.secondary.opacity(0.42),
                        ReclaimColors.cream,
                        ReclaimColors.primary.opacity(0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        ReclaimBadge(text: viewModel.isSessionActive ? "En cours" : "Pret", color: viewModel.isSessionActive ? ReclaimColors.success : ReclaimColors.primary)

                        Text(viewModel.isSessionActive ? "Tu récupères du temps." : "Choisis ton rythme, Reclaim tient le temps.")
                            .font(.system(size: 31, weight: .black, design: .rounded))
                            .foregroundStyle(ReclaimColors.text)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(viewModel.hasRealSelection ? viewModel.realSelectionSummary : "Ajoute tes apps surveillées dans Réglages.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ReclaimColors.muted)
                    }

                    Spacer()

                    ReclaimMascotView(state: viewModel.mascotState, size: 150)
                        .offset(x: 12, y: 12)
                }
                .padding(22)
            }
            .frame(minHeight: 230)
        }
    }

    private var currentBlockCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: currentBlockSymbol)
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(currentBlockColor)
                        .frame(width: 58, height: 58)
                        .background(currentBlockColor.opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {

                        Text(viewModel.activeBlockTitle)
                            .font(ReclaimTypography.section)
                            .foregroundStyle(ReclaimColors.text)

                        ReclaimBadge(text: currentStatus, color: currentBlockColor)
                    }

                    Spacer()
                }

                if viewModel.isSessionActive {
                    ReclaimButton(
                        title: currentActionTitle,
                        symbol: currentActionSymbol,
                        isPrimary: false,
                        action: currentAction
                    )
                } else if viewModel.isSessionLimitSnoozed {
                    ReclaimButton(
                        title: "Reprendre le blocage",
                        symbol: "lock.fill",
                        isPrimary: false
                    ) {
                        viewModel.endSessionLimitSnooze()
                    }
                } else if viewModel.canSnoozeSessionLimit {
                    ReclaimButton(
                        title: "Snooze 5 min",
                        symbol: "moon.zzz.fill",
                        isPrimary: false
                    ) {
                        viewModel.prepareSessionLimitSnoozeChallenge()
                        isSnoozeChallengePresented = true
                    }
                }
            }
        }
    }

    private var dayScreenTimeCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Temps d'écran du jour des apps surveillées")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ReclaimColors.muted)

                if !viewModel.canEstimateScreenTime {
                    unavailableScreenTimeState
                } else if !viewModel.hasReclaimScreenTimeData {
                    noReclaimDataState
                } else {
                    screenTimeChartContent
                }
            }
        }
    }

    private var unavailableScreenTimeState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Indisponible sans autorisation")
                .font(ReclaimTypography.section)
                .foregroundStyle(ReclaimColors.text)
            Text("Autorise Screen Time dans Paramètres pour afficher les estimations basées sur le temps d'écran.")
                .font(.subheadline)
                .foregroundStyle(ReclaimColors.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
    }

    private var noReclaimDataState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pas encore de données Reclaim")
                .font(ReclaimTypography.section)
                .foregroundStyle(ReclaimColors.text)
            Text("Choisis tes apps surveillées et active le blocage scroll. L'évolution sur 24h apparaîtra après les premières données observées par Reclaim.")
                .font(.subheadline)
                .foregroundStyle(ReclaimColors.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
    }

    private var screenTimeChartContent: some View {
        VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(viewModel.estimatedScreenMinutesToday)m")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(ReclaimColors.text)

                    ReclaimBadge(text: "\(viewModel.estimatedSavedMinutesToday)m récupérées", color: ReclaimColors.success)
                }

                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { proxy in
                        ZStack(alignment: .bottomLeading) {
                            chartGrid(in: proxy.size)
                                .stroke(ReclaimColors.border, lineWidth: 1)

                            Path { path in
                                let width = proxy.size.width
                                let height = proxy.size.height
                                path.move(to: CGPoint(x: 0, y: height * 0.92))
                                path.addLine(to: CGPoint(x: width, y: yPosition(for: viewModel.baselineSettings.baselineDailyScreenMinutes, height: height)))
                            }
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [7, 7]))
                            .foregroundStyle(ReclaimColors.muted.opacity(0.42))

                            Path { path in
                                let width = proxy.size.width
                                let height = proxy.size.height
                                let nowX = width * CGFloat(viewModel.dayProgressFraction)
                                path.move(to: CGPoint(x: 0, y: height * 0.92))
                                path.addLine(to: CGPoint(x: max(8, nowX), y: yPosition(for: viewModel.estimatedScreenMinutesToday, height: height)))
                            }
                            .stroke(ReclaimColors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        }
                    }
                    .frame(height: 130)

                    HStack {
                        Text("0:00")
                        Spacer()
                        Text("6:00")
                        Spacer()
                        Text("12:00")
                        Spacer()
                        Text("18:00")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ReclaimColors.muted.opacity(0.72))

                    HStack(spacing: 14) {
                        ChartLegend(color: ReclaimColors.primary, text: "Usage estimé actuel")
                        ChartLegend(color: ReclaimColors.muted.opacity(0.45), text: "Baseline avant Reclaim", dashed: true)
                    }
                }
        }
    }

    private var nextBlocksCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Mes prochains blocages")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ReclaimColors.muted)

                if viewModel.nextScheduledBlocksToday.isEmpty {
                    Text("Aucun autre blocage prévu aujourd'hui.")
                        .font(.subheadline)
                        .foregroundStyle(ReclaimColors.muted)
                } else {
                    ForEach(viewModel.nextScheduledBlocksToday.prefix(3)) { block in
                        HStack(spacing: 14) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(ReclaimColors.accent)
                                .frame(width: 52, height: 52)
                                .background(ReclaimColors.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(block.name)
                                    .font(ReclaimTypography.cardTitle)
                                    .foregroundStyle(ReclaimColors.text)
                                Text(block.scheduleSummary)
                                    .font(.subheadline)
                                    .foregroundStyle(ReclaimColors.muted)
                            }
                        }
                    }
                }
            }
        }
    }

    private func yPosition(for minutes: Int, height: CGFloat) -> CGFloat {
        let maxMinutes = max(viewModel.baselineSettings.baselineDailyScreenMinutes, 60)
        let ratio = min(max(Double(minutes) / Double(maxMinutes), 0), 1)
        return height * (0.92 - CGFloat(ratio) * 0.80)
    }

    private func chartGrid(in size: CGSize) -> Path {
        Path { path in
            for step in 0...2 {
                let y = size.height * CGFloat(step) / 2
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
    }

    private var currentStatus: String {
        switch viewModel.sessionState {
        case .inactive:
            if viewModel.isSessionLimitSnoozed {
                return "Pause \(viewModel.formattedTime(viewModel.sessionLimitSnoozeRemainingSeconds))"
            }
            return viewModel.sessionLimitSettings.isEnabled ? "Surveille" : "Inactif"
        case .active:
            return "Bloque"
        case .temporaryUnlock:
            return "Pause active"
        }
    }

    private var currentActionTitle: String {
        switch viewModel.sessionState {
        case .inactive: "Activer"
        case .active: "Pause"
        case .temporaryUnlock: "Reprendre"
        }
    }

    private var currentActionSymbol: String {
        switch viewModel.sessionState {
        case .inactive: "play.fill"
        case .active: "pause.fill"
        case .temporaryUnlock: "lock.fill"
        }
    }

    private var currentBlockSymbol: String {
        switch viewModel.sessionState {
        case .inactive: "hourglass"
        case .active: "lock.fill"
        case .temporaryUnlock: "cup.and.saucer.fill"
        }
    }

    private var currentBlockColor: Color {
        switch viewModel.sessionState {
        case .inactive: ReclaimColors.primary
        case .active: ReclaimColors.primary
        case .temporaryUnlock: ReclaimColors.accent
        }
    }

    private func currentAction() {
        switch viewModel.sessionState {
        case .inactive:
            startFocus()
        case .active:
            if viewModel.strictMode.requiresChallenge {
                viewModel.registerUnlockAttempt()
                isChallengePresented = true
            } else {
                viewModel.grantPauseWithoutChallenge()
            }
        case .temporaryUnlock:
            _ = viewModel.startFocusWithSelectedDuration()
        }
    }
}

private struct ChartLegend: View {
    let color: Color
    let text: String
    var dashed = false

    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .stroke(color, style: StrokeStyle(lineWidth: 3, dash: dashed ? [5, 4] : []))
                .frame(width: 22, height: 3)
            Text(text)
                .font(.caption2.weight(.bold))
                .foregroundStyle(ReclaimColors.muted)
        }
    }
}
