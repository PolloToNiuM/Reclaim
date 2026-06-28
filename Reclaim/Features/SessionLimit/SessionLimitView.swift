import SwiftUI

struct SessionLimitView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel

    var body: some View {
        ZStack {
            ReclaimBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    settingsCard

                    if !viewModel.deviceActivityMessage.isEmpty {
                        Text(viewModel.deviceActivityMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ReclaimColors.muted)
                            .padding(.horizontal, 4)
                    }

                    ReclaimButton(
                        title: viewModel.sessionLimitSettings.isEnabled ? "Mettre à jour la limite" : "Activer la limite",
                        symbol: "hourglass"
                    ) {
                        if !viewModel.sessionLimitSettings.isEnabled {
                            viewModel.sessionLimitSettings.isEnabled = true
                        }
                        viewModel.configureSessionLimitMonitoring()
                    }

                    ReclaimButton(title: "Désactiver la limite", symbol: "xmark", isPrimary: false) {
                        viewModel.sessionLimitSettings.isEnabled = false
                        viewModel.stopSessionLimitMonitoring()
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Limite")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Limite anti-scroll", systemImage: "hourglass")
                        .font(ReclaimTypography.section)
                        .foregroundStyle(ReclaimColors.text)
                    Spacer()
                    ReclaimBadge(
                        text: viewModel.sessionLimitSettings.isEnabled ? "Active" : "Inactive",
                        color: viewModel.sessionLimitSettings.isEnabled ? ReclaimColors.mint : ReclaimColors.blue
                    )
                }

                Text("Reclaim intervient quand iOS détecte une longue utilisation des apps choisies dans une fenêtre Screen Time. Le shield reste appliqué jusqu'à l'arrêt manuel ou la fin de la fenêtre iOS.")
                    .font(.subheadline)
                    .foregroundStyle(ReclaimColors.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.hasRealSelection ? viewModel.realSelectionSummary : "Aucune sélection Screen Time configurée")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ReclaimColors.muted)
            }
        }
    }

    private var settingsCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 18) {
                Toggle("Activer", isOn: $viewModel.sessionLimitSettings.isEnabled)
                    .tint(ReclaimColors.mint)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bloquer après")
                        .font(ReclaimTypography.cardTitle)
                    optionRow(
                        options: SessionLimitSettings.usageOptions,
                        selection: $viewModel.sessionLimitSettings.usageThresholdMinutes,
                        suffix: "min"
                    )
                }

                Text("La durée fine du blocage et le challenge obligatoire sont gardés pour V4, afin d'éviter de promettre un comportement que iOS ne garantit pas encore ici.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ReclaimColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(ReclaimColors.text)
        }
    }

    private func optionRow(options: [Int], selection: Binding<Int>, suffix: String) -> some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { value in
                Button {
                    selection.wrappedValue = value
                } label: {
                    Text("\(value)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection.wrappedValue == value ? ReclaimColors.mint : ReclaimColors.panelStrong)
                        .foregroundStyle(selection.wrappedValue == value ? .white : ReclaimColors.text)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(value) \(suffix)")
            }
        }
    }
}
