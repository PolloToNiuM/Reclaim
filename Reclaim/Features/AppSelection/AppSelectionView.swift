import SwiftUI

struct AppSelectionView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ReclaimScreenHeader(
                        title: "Apps surveillées",
                        subtitle: "Un seul groupe simple pour commencer, centré sur le temps récupéré."
                    )

                    summaryCard

                    if viewModel.screenTimeAuthorization.isAuthorized {
                        RealAppSelectionView()
                    } else {
                        ScreenTimePermissionView()
                    }

                }
                .padding(20)
            }
        }
    }

    private var summaryCard: some View {
        ReclaimCard {
            HStack(spacing: 14) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(ReclaimColors.accent)
                    .frame(width: 56, height: 56)
                    .background(ReclaimColors.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Groupe principal")
                        .font(ReclaimTypography.section)
                        .foregroundStyle(ReclaimColors.text)
                    Text(viewModel.hasRealSelection ? viewModel.realSelectionSummary : "Aucune app sélectionnée")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ReclaimColors.muted)
                }

                Spacer()

                ReclaimBadge(text: viewModel.hasRealSelection ? "Prêt" : "À faire", color: viewModel.hasRealSelection ? ReclaimColors.success : ReclaimColors.primary)
            }
        }
    }
}
