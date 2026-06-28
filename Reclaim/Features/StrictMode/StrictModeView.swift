import SwiftUI

struct StrictModeView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel

    var body: some View {
        ZStack {
            ReclaimBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Mode strict")
                        .font(ReclaimTypography.title)
                        .foregroundStyle(ReclaimColors.text)

                    ReclaimCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Toggle("Autoriser les pauses", isOn: $viewModel.strictMode.allowsPauses)
                            Toggle("Challenge obligatoire", isOn: $viewModel.strictMode.requiresChallenge)

                            Picker("Délai avant pause", selection: $viewModel.strictMode.pauseDelay) {
                                ForEach(PauseDelay.allCases) { delay in
                                    Text(delay.label).tag(delay)
                                }
                            }
                            .pickerStyle(.segmented)

                            Picker("Pause maximale", selection: $viewModel.strictMode.maxPauseDuration) {
                                ForEach(PauseDuration.allCases) { duration in
                                    Text(duration.label).tag(duration)
                                }
                            }
                            .pickerStyle(.segmented)

                            Picker("Difficulté", selection: $viewModel.strictMode.challengeDifficulty) {
                                ForEach(ChallengeDifficulty.allCases) { difficulty in
                                    Text(difficulty.label).tag(difficulty)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .tint(ReclaimColors.mint)
                        .foregroundStyle(ReclaimColors.text)
                    }

                    ReclaimCard {
                        HStack(spacing: 14) {
                            ReclaimMascotView(state: viewModel.strictMode.allowsPauses ? .idle : .blocked)
                                .scaleEffect(0.72)

                            Text(viewModel.strictMode.allowsPauses ? "Les pauses restent possibles, avec une friction douce." : "Les pauses sont désactivées pour tenir ton intention.")
                                .font(.headline)
                                .foregroundStyle(ReclaimColors.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Strict")
        .navigationBarTitleDisplayMode(.inline)
    }
}
