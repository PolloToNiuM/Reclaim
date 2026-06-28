import SwiftUI

struct FocusSessionView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if viewModel.isSessionActive {
                        timerCard
                        blockedAppsCard
                        pauseSection

                        ReclaimButton(title: "Terminer la session", symbol: "xmark", isPrimary: false) {
                            withAnimation {
                                viewModel.endFocus()
                            }
                        }
                        .accessibilityLabel("Terminer la session de focus")
                    } else {
                        emptyState
                    }
                }
                .padding(20)
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var timerCard: some View {
        ReclaimCard {
            VStack(spacing: 18) {
                ReclaimProgressRing(progress: viewModel.progress) {
                    VStack(spacing: 8) {
                        ReclaimMascotView(state: viewModel.mascotState)
                            .scaleEffect(0.62)

                        Text(viewModel.formattedTime(viewModel.remainingSeconds))
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(ReclaimColors.text)

                        Text(viewModel.sessionState.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ReclaimColors.muted)
                    }
                }
                .frame(width: 270, height: 270)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var blockedAppsCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Blocage Screen Time")
                        .font(ReclaimTypography.cardTitle)
                        .foregroundStyle(ReclaimColors.text)

                    Spacer()
                    ReclaimBadge(text: lockBadge, color: lockColor)
                }

                if viewModel.screenTimeAuthorization.isAuthorized {
                    Label(viewModel.realSelectionSummary, systemImage: "shield.lefthalf.filled")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ReclaimColors.text)
                } else {
                    Label("Autorisation Screen Time requise", systemImage: "exclamationmark.shield.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ReclaimColors.text)
                }

                if !viewModel.shieldMessage.isEmpty {
                    Text(viewModel.shieldMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ReclaimColors.muted)
                }
            }
        }
    }

    private var pauseSection: some View {
        Group {
            if viewModel.canRequestPause() {
                NavigationLink {
                    MathChallengeView()
                } label: {
                    Label("J'ai vraiment besoin d'accès", systemImage: "lock.open")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ReclaimColors.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.registerUnlockAttempt()
                })
                .accessibilityLabel("Demander une pause avec challenge")
            } else {
                ReclaimCard {
                    Label("Les pauses sont désactivées par le mode strict.", systemImage: "lock.shield.fill")
                        .font(.headline)
                        .foregroundStyle(ReclaimColors.coral)
                }
            }
        }
    }

    private var emptyState: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 12) {
                ReclaimMascotView(state: .idle)
                    .scaleEffect(0.8)
                    .frame(maxWidth: .infinity)

                Text("Aucune session active")
                    .font(ReclaimTypography.title)
                    .foregroundStyle(ReclaimColors.text)

                Text("Lance un blocage depuis Home ou depuis l'onglet Blocages.")
                    .foregroundStyle(ReclaimColors.muted)
            }
        }
        .padding(.top, 30)
    }

    private var lockBadge: String {
        if case .temporaryUnlock = viewModel.sessionState {
            return "Pause"
        }
        return viewModel.isRealShieldActive ? "Reel" : "A configurer"
    }

    private var lockColor: Color {
        if case .temporaryUnlock = viewModel.sessionState {
            return ReclaimColors.yellow
        }
        return viewModel.isRealShieldActive ? ReclaimColors.mint : ReclaimColors.blue
    }
}
