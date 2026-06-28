import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = ReclaimViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            ReclaimBackground()

            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView {
                        if !viewModel.isSessionActive {
                            withAnimation {
                                _ = viewModel.startFocusWithSelectedDuration()
                            }
                        }
                    }
                }
                .tabItem { Label("Accueil", systemImage: "house.fill") }
                .tag(0)

                BlockingView()
                    .tabItem { Label("Blocages", systemImage: "lock.shield.fill") }
                    .tag(1)

                StatsView()
                    .tabItem { Label("Progrès", systemImage: "circle.grid.2x2.fill") }
                    .tag(2)

                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label("Paramètres", systemImage: "gearshape.fill") }
                .tag(3)
            }
            .environmentObject(viewModel)
            .tint(ReclaimColors.primary)
        }
        .fullScreenCover(isPresented: onboardingBinding) {
            BaselineOnboardingView()
                .environmentObject(viewModel)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            guard viewModel.baselineSettings.isOnboardingComplete else { return }
            guard viewModel.sessionLimitSettings.isEnabled else { return }
            viewModel.configureSessionLimitMonitoring()
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding {
            !viewModel.baselineSettings.isOnboardingComplete
        } set: { _ in }
    }
}
