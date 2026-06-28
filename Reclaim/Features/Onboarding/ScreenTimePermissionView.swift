import SwiftUI

struct ScreenTimePermissionView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel

    var body: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: permissionSymbol)
                        .font(.title3)
                        .foregroundStyle(permissionColor)
                        .frame(width: 40, height: 40)
                        .background(ReclaimColors.panelStrong)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Activer les permissions Reclaim")
                            .font(.headline)
                            .foregroundStyle(ReclaimColors.text)

                        Text(viewModel.screenTimeAuthorization.label)
                            .font(.caption)
                            .foregroundStyle(ReclaimColors.muted)
                    }
                }

                Text("Reclaim utilise les APIs Screen Time d'Apple pour bloquer les apps que tu choisis et t'aider à récupérer du temps.")
                    .font(.subheadline)
                    .foregroundStyle(ReclaimColors.muted)

                if case let .failed(message) = viewModel.screenTimeAuthorization {
                    Text(message)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ReclaimColors.muted)
                }

                ReclaimButton(title: "Autoriser Screen Time", symbol: "person.badge.shield.checkmark") {
                    Task {
                        await viewModel.requestScreenTimeAuthorization()
                    }
                }
            }
        }
    }

    private var permissionSymbol: String {
        switch viewModel.screenTimeAuthorization {
        case .authorized:
            "checkmark.shield.fill"
        case .denied, .failed:
            "exclamationmark.shield.fill"
        case .notDetermined:
            "shield.fill"
        }
    }

    private var permissionColor: Color {
        viewModel.screenTimeAuthorization.isAuthorized ? ReclaimColors.mint : ReclaimColors.blue
    }
}
