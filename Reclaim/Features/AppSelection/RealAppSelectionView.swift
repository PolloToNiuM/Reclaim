import FamilyControls
import SwiftUI

struct RealAppSelectionView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel
    @State private var isPickerPresented = false

    var body: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sélection Screen Time")
                            .font(ReclaimTypography.cardTitle)
                            .foregroundStyle(ReclaimColors.text)

                        Text(viewModel.realSelectionSummary)
                            .font(.subheadline)
                            .foregroundStyle(ReclaimColors.muted)
                    }

                    Spacer()

                    Image(systemName: viewModel.hasRealSelection ? "checkmark.circle.fill" : "circle.dashed")
                        .font(.title2)
                        .foregroundStyle(viewModel.hasRealSelection ? ReclaimColors.success : ReclaimColors.muted)
                }

                ReclaimButton(title: viewModel.hasRealSelection ? "Modifier la sélection" : "Choisir les apps", symbol: "square.grid.2x2.fill") {
                    isPickerPresented = true
                }
            }
        }
        .familyActivityPicker(
            title: "Apps à bloquer",
            headerText: "Sélectionne les apps, catégories ou domaines que Reclaim doit bloquer pendant le focus.",
            footerText: "Tu peux modifier cette sélection à tout moment.",
            isPresented: $isPickerPresented,
            selection: selectionBinding
        )
    }

    private var selectionBinding: Binding<FamilyActivitySelection> {
        Binding {
            viewModel.realSelection
        } set: { selection in
            viewModel.realSelection = selection
        }
    }
}
