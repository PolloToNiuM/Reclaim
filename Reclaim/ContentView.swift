import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.08, green: 0.10, blue: 0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("Reclaim")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Reprends ton temps. Une session à la fois.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 16) {
                        Button {
                            // TODO: Start focus session
                        } label: {
                            Text("Start Focus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.white)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        Button {
                            // TODO: Configure apps
                        } label: {
                            Text("Choisir les apps à bloquer")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.white.opacity(0.12))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 80)
            }
        }
    }
}

#Preview {
    ContentView()
}
