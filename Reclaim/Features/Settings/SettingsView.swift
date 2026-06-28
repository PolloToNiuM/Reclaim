import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel
    @State private var protectedAction: ProtectedSettingsAction?

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ReclaimScreenHeader(
                        title: "Paramètres",
                        subtitle: "Les réglages globaux de Reclaim, sans encombrer l'accueil."
                    )

                    if !viewModel.screenTimeAuthorization.isAuthorized {
                        ScreenTimePermissionView()
                    }

                    NavigationLink {
                        AppSelectionView()
                            .navigationTitle("Groupe principal")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        SettingsRow(
                            symbol: "square.grid.2x2.fill",
                            title: "Groupe principal",
                            subtitle: viewModel.hasRealSelection ? viewModel.realSelectionSummary : "Choisir les apps surveillées",
                            color: ReclaimColors.accent
                        )
                    }
                    .buttonStyle(.plain)

                    SettingsToggleRow(
                        symbol: "function",
                        title: "Challenges",
                        subtitle: "Mini-défi avant une pause ou un déverrouillage.",
                        color: ReclaimColors.primary,
                        isOn: viewModel.strictMode.requiresChallenge
                    ) {
                        if viewModel.strictMode.requiresChallenge {
                            requestProtectedAction(.disableChallenges)
                        } else {
                            viewModel.strictMode.requiresChallenge = true
                        }
                    }

                    SettingsToggleRow(
                        symbol: "hourglass",
                        title: "Blocage scroll",
                        subtitle: "Surveille les sessions longues sur tes apps.",
                        color: ReclaimColors.primary,
                        isOn: viewModel.sessionLimitSettings.isEnabled
                    ) {
                        if viewModel.sessionLimitSettings.isEnabled {
                            if viewModel.strictMode.requiresChallenge {
                                requestProtectedAction(.disableScrollBlock)
                            } else {
                                disableScrollBlock()
                            }
                        } else {
                            viewModel.sessionLimitSettings.isEnabled = true
                            viewModel.configureSessionLimitMonitoring()
                        }
                    }

                    NavigationLink {
                        ScreenTimeDebugLogView()
                            .navigationTitle("Logs Screen Time")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        SettingsRow(
                            symbol: "ladybug.fill",
                            title: "Logs Screen Time",
                            subtitle: "Diagnostic temporaire du blocage scroll.",
                            color: ReclaimColors.accent
                        )
                    }
                    .buttonStyle(.plain)

                    if !viewModel.deviceActivityMessage.isEmpty {
                        Text(viewModel.deviceActivityMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ReclaimColors.muted)
                    }
                }
                .padding(20)
                .padding(.bottom, 18)
            }
        }
        .sheet(item: $protectedAction) { action in
            SettingsChallengeSheet(action: action) {
                applyProtectedAction(action)
                protectedAction = nil
            }
            .environmentObject(viewModel)
            .presentationDetents([.medium])
        }
    }

    private func requestProtectedAction(_ action: ProtectedSettingsAction) {
        viewModel.prepareSettingsChallenge()
        protectedAction = action
    }

    private func applyProtectedAction(_ action: ProtectedSettingsAction) {
        switch action {
        case .disableChallenges:
            viewModel.strictMode.requiresChallenge = false
        case .disableScrollBlock:
            disableScrollBlock()
        }
    }

    private func disableScrollBlock() {
        viewModel.sessionLimitSettings.isEnabled = false
        viewModel.stopSessionLimitMonitoring()
    }
}

private struct ScreenTimeDebugLogView: View {
    @State private var logText = ""
    @State private var copyMessage = ""

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ReclaimScreenHeader(
                        title: "Logs Screen Time",
                        subtitle: "À copier après un test de blocage scroll."
                    )

                    HStack(spacing: 10) {
                        Button("Rafraîchir") {
                            refresh()
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(ReclaimColors.primary)

                        Spacer()

                        Button("Copier") {
                            UIPasteboard.general.string = logText
                            copyMessage = "Logs copiés."
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(ReclaimColors.accent)

                        Button("Effacer") {
                            ScreenTimeSharedStore.clearDebugLog()
                            refresh()
                            copyMessage = "Logs effacés."
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(ReclaimColors.danger)
                    }

                    if !copyMessage.isEmpty {
                        Text(copyMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ReclaimColors.muted)
                    }

                    ReclaimCard {
                        if logText.isEmpty {
                            Text("Aucun log pour le moment.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ReclaimColors.muted)
                        } else {
                            Text(logText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(ReclaimColors.text)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(20)
            }
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        logText = ScreenTimeSharedStore.loadDebugLogText()
    }
}

private enum ProtectedSettingsAction: String, Identifiable {
    case disableChallenges
    case disableScrollBlock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .disableChallenges: "Desactiver les challenges"
        case .disableScrollBlock: "Desactiver le blocage scroll"
        }
    }

    var subtitle: String {
        "Un mini-challenge confirme que c'est vraiment ton choix."
    }
}

private struct SettingsRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        ReclaimCard {
            HStack(spacing: 15) {
                Image(systemName: symbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(color)
                    .frame(width: 54, height: 54)
                    .background(color.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(ReclaimTypography.cardTitle)
                        .foregroundStyle(ReclaimColors.text)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ReclaimColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.black))
                    .foregroundStyle(ReclaimColors.muted)
            }
        }
    }
}

private struct SettingsToggleRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let color: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ReclaimCard {
            HStack(spacing: 15) {
                Image(systemName: symbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isOn ? color : ReclaimColors.muted)
                    .frame(width: 54, height: 54)
                    .background((isOn ? color : ReclaimColors.muted).opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(ReclaimTypography.cardTitle)
                        .foregroundStyle(ReclaimColors.text)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ReclaimColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("", isOn: .constant(isOn))
                    .labelsHidden()
                    .tint(color)
                    .allowsHitTesting(false)
            }
        }
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsChallengeSheet: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel
    @Environment(\.dismiss) private var dismiss
    let action: ProtectedSettingsAction
    let onSuccess: () -> Void
    @State private var answer = ""

    var body: some View {
        ZStack {
            ReclaimBackground()
            VStack(alignment: .leading, spacing: 18) {
                Text(action.title)
                    .font(ReclaimTypography.title)
                    .foregroundStyle(ReclaimColors.text)

                Text(action.subtitle)
                    .font(.headline)
                    .foregroundStyle(ReclaimColors.muted)

                ReclaimCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(viewModel.challenge.question)
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(ReclaimColors.text)

                        TextField("Réponse", text: $answer)
                            .keyboardType(.numberPad)
                            .font(.title2.bold())
                            .padding(14)
                            .background(ReclaimColors.panelStrong)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }

                if !viewModel.challengeMessage.isEmpty {
                    Text(viewModel.challengeMessage)
                        .font(.headline)
                        .foregroundStyle(ReclaimColors.muted)
                }

                ReclaimButton(title: "Valider", symbol: "checkmark") {
                    if viewModel.validateChallengeOnly(answer) {
                        onSuccess()
                        dismiss()
                    }
                }
            }
            .padding(22)
        }
    }
}
