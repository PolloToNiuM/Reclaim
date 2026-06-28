import SwiftUI

struct BlockingView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                ReclaimBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ReclaimScreenHeader(title: "Blocages")

                        VStack(spacing: 16) {
                            NavigationLink {
                                ScrollBlockSettingsView()
                            } label: {
                                BlockingHubRow(
                                    symbol: "hourglass",
                                    title: "Blocage scroll",
                                    subtitle: viewModel.sessionLimitSettings.isEnabled ? "Surveille" : "Inactif",
                                    detail: "\(viewModel.sessionLimitSettings.usageThresholdMinutes) min puis \(viewModel.sessionLimitSettings.blockDurationMinutes) min",
                                    color: ReclaimColors.primary
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                ScheduleView()
                            } label: {
                                BlockingHubRow(
                                    symbol: "calendar",
                                    title: "Blocages planifiés (\(viewModel.scheduledBlocks.count))",
                                    subtitle: "Jours et horaires récurrents",
                                    detail: "\(viewModel.scheduledBlocks.count)/\(viewModel.maximumScheduledBlocks)",
                                    color: ReclaimColors.primary
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                ImmediateBlockSettingsView()
                            } label: {
                                BlockingHubRow(
                                    symbol: "bolt.fill",
                                    title: "Blocage immédiat",
                                    subtitle: "Bloque tes apps maintenant",
                                    detail: "\(viewModel.selectedFocusMinutes) min",
                                    color: ReclaimColors.primary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 18)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ScrollBlockSettingsView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(spacing: 18) {
                    DetailHero(
                        symbol: "hourglass",
                        color: ReclaimColors.primary,
                        title: "Blocage scroll",
                        subtitle: "Si tes apps de scroll atteignent \(viewModel.sessionLimitSettings.usageThresholdMinutes) min d'utilisation, elles se bloquent \(viewModel.sessionLimitSettings.blockDurationMinutes) min puis se déverrouillent automatiquement."
                    )

                    ReclaimCard {
                        ReclaimDurationPicker(
                            title: "Temps avant blocage",
                            values: SessionLimitSettings.usageOptions,
                            suffix: "minutes",
                            selection: $viewModel.sessionLimitSettings.usageThresholdMinutes
                        )
                    }

                    ReclaimCard {
                        ReclaimDurationPicker(
                            title: "Durée de blocage",
                            values: SessionLimitSettings.blockOptions,
                            suffix: "minutes",
                            selection: $viewModel.sessionLimitSettings.blockDurationMinutes
                        )
                    }

                    NavigationLink {
                        AppSelectionView()
                            .navigationTitle("Groupe principal")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        SettingsNavigationRow(
                            symbol: "square.grid.2x2.fill",
                            title: "Voir mes apps",
                            subtitle: viewModel.hasRealSelection ? viewModel.realSelectionSummary : "Choisir le groupe principal",
                            color: ReclaimColors.primary
                        )
                    }
                    .buttonStyle(.plain)

                    ToggleCard(
                        title: "Activer le blocage scroll",
                        subtitle: "Surveille les apps choisies avec DeviceActivity.",
                        symbol: "eye.fill",
                        isOn: $viewModel.sessionLimitSettings.isEnabled
                    )
                    .onChange(of: viewModel.sessionLimitSettings.isEnabled) { _, isEnabled in
                        if isEnabled {
                            viewModel.configureSessionLimitMonitoring()
                        } else {
                            viewModel.stopSessionLimitMonitoring()
                        }
                    }

                    if !viewModel.deviceActivityMessage.isEmpty {
                        Text(viewModel.deviceActivityMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ReclaimColors.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                }
                .padding(20)
                .padding(.bottom, 96)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        ReclaimColors.background.opacity(0),
                        ReclaimColors.background.opacity(0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 18)

                ReclaimButton(title: "Enregistrer", symbol: "checkmark") {
                    if viewModel.sessionLimitSettings.isEnabled {
                        viewModel.configureSessionLimitMonitoring()
                    }
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .background(ReclaimColors.background.opacity(0.96))
            }
        }
        .navigationTitle("Blocage scroll")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ImmediateBlockSettingsView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(spacing: 18) {
                    DetailHero(
                        symbol: "bolt.fill",
                        color: ReclaimColors.primary,
                        title: "Blocage immédiat",
                        subtitle: "Bloque tes apps pendant \(viewModel.selectedFocusMinutes) minutes. Tes apps se débloquent toutes seules."
                    )

                    NavigationLink {
                        AppSelectionView()
                            .navigationTitle("Groupe principal")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        SettingsNavigationRow(
                            symbol: "apps.iphone",
                            title: "Choisis tes apps",
                            subtitle: viewModel.hasRealSelection ? viewModel.realSelectionSummary : "Aucune app sélectionnée",
                            color: ReclaimColors.primary
                        )
                    }
                    .buttonStyle(.plain)

                    ReclaimCard {
                        ReclaimDurationPicker(
                            title: "Durée",
                            values: [5, 10, 15, 20, 25, 30, 45, 60],
                            suffix: "minutes",
                            selection: $viewModel.selectedFocusMinutes
                        )
                    }

                    ToggleCard(
                        title: "Challenges",
                        subtitle: "Demande un mini-challenge avant une pause.",
                        symbol: "function",
                        isOn: $viewModel.strictMode.requiresChallenge
                    )

                    ReclaimButton(title: "Bloquer pour \(viewModel.selectedFocusMinutes) minutes", symbol: "lock.fill") {
                        _ = viewModel.startFocusWithSelectedDuration()
                    }

                    if !viewModel.shieldMessage.isEmpty {
                        Text(viewModel.shieldMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ReclaimColors.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Blocage immédiat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BlockingHubRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 18) {
            IconBubble(symbol: symbol, color: color)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(ReclaimTypography.section)
                    .foregroundStyle(ReclaimColors.text)
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ReclaimColors.muted)
                ReclaimBadge(text: detail, color: color)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(ReclaimColors.primary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .background(ReclaimColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(ReclaimColors.primary, lineWidth: 3)
        }
    }
}

private struct DetailHero: View {
    let symbol: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 92, height: 92)
                .background(color.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            Text(title)
                .font(ReclaimTypography.title)
                .foregroundStyle(ReclaimColors.text)

            Text(subtitle)
                .font(.headline)
                .foregroundStyle(ReclaimColors.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

private struct SettingsNavigationRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        ReclaimCard {
            HStack(spacing: 16) {
                IconBubble(symbol: symbol, color: color)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(ReclaimTypography.section)
                        .foregroundStyle(ReclaimColors.text)
                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ReclaimColors.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.title2.weight(.black))
                    .foregroundStyle(ReclaimColors.muted)
            }
        }
    }
}

private struct ToggleCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        ReclaimCard {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(isOn ? ReclaimColors.primary : ReclaimColors.muted)
                    .frame(width: 46, height: 46)
                    .background((isOn ? ReclaimColors.primary : ReclaimColors.muted).opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(ReclaimTypography.cardTitle)
                        .foregroundStyle(isOn ? ReclaimColors.primary : ReclaimColors.text)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ReclaimColors.muted)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(ReclaimColors.primary)
            }
        }
    }
}

private struct IconBubble: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 66, height: 66)
            .background(color.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
