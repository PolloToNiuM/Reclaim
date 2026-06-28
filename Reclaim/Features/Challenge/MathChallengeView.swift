import SwiftUI

struct MathChallengeView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel
    @Environment(\.dismiss) private var dismiss
    let title: String
    let subtitle: String
    let successButtonTitle: String
    let validateAnswer: ((String) -> Bool)?
    @State private var answer = ""
    @State private var didSucceed = false

    init(
        title: String = "Mini challenge",
        subtitle: String = "Une petite pause pour vérifier que c'est bien ton choix.",
        successButtonTitle: String = "Retour au focus",
        validateAnswer: ((String) -> Bool)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.successButtonTitle = successButtonTitle
        self.validateAnswer = validateAnswer
    }

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 16) {
                        ReclaimMascotView(state: didSucceed ? .success : .focus)
                            .scaleEffect(0.82)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(ReclaimTypography.title)
                                .foregroundStyle(ReclaimColors.text)

                            ReclaimBadge(text: viewModel.strictMode.challengeDifficulty.label, color: ReclaimColors.blue)
                        }
                    }

                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(ReclaimColors.muted)

                    ReclaimCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(viewModel.challenge.question)
                                .font(.system(size: 44, weight: .black, design: .rounded))
                                .foregroundStyle(ReclaimColors.text)

                            TextField("Réponse", text: $answer)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)
                                .font(.title2.bold())
                                .padding(16)
                                .background(ReclaimColors.panelStrong)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .foregroundStyle(ReclaimColors.text)
                                .accessibilityLabel("Réponse au challenge")
                        }
                    }

                    if !viewModel.challengeMessage.isEmpty {
                        Text(viewModel.challengeMessage)
                            .font(.headline)
                            .foregroundStyle(didSucceed ? ReclaimColors.mintDark : ReclaimColors.muted)
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    ReclaimButton(title: "Valider", symbol: "checkmark") {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            didSucceed = validateAnswer?(answer) ?? viewModel.submitChallengeAnswer(answer)
                        }
                    }
                    .accessibilityLabel("Valider la réponse")

                    if didSucceed {
                        ReclaimButton(title: successButtonTitle, symbol: "arrow.left", isPrimary: false) {
                            dismiss()
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
