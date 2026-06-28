import SwiftUI

struct BaselineOnboardingView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel
    @State private var step = 0
    @State private var age = 23
    @State private var dailyMinutes = 240
    @State private var isRequestingAuthorization = false
    @State private var animatedDots = 0
    @State private var visibleLifeDots = 0
    @State private var livedLifeDots = 0
    @State private var phoneLifeDots = 0
    @State private var projectionPhaseText = ""
    @State private var isProjectionComplete = false

    private let totalSteps = 5
    private var lifeExpectancy: Int {
        age >= 75 ? age + 5 : 80
    }

    private var remainingLifeYears: Int {
        max(0, lifeExpectancy - age)
    }

    var body: some View {
        ZStack {
            ReclaimBackground()

            VStack(spacing: 22) {
                Spacer(minLength: 18)

                progressPills

                Group {
                    switch step {
                    case 0:
                        intentionStep
                    case 1:
                        ageStep
                    case 2:
                        authorizationStep
                    case 3:
                        appSelectionStep
                    default:
                        projectionStep
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.86), value: step)

                Spacer(minLength: 10)

                ReclaimButton(title: primaryButtonTitle, symbol: primaryButtonSymbol) {
                    primaryAction()
                }
                .disabled(!canTapPrimaryButton)
                .opacity(canShowPrimaryButton ? 1 : 0)
                .scaleEffect(canShowPrimaryButton ? 1 : 0.94)
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: canShowPrimaryButton)
            }
            .padding(24)
        }
        .interactiveDismissDisabled()
        .onAppear {
            age = viewModel.baselineSettings.age
            dailyMinutes = viewModel.baselineSettings.baselineDailyScreenMinutes
        }
        .onChange(of: step) { _, newStep in
            if newStep == 4 {
                animateDots()
            }
        }
    }

    private var progressPills: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? ReclaimColors.primary : ReclaimColors.border)
                    .frame(width: index == step ? 34 : 10, height: 10)
            }
        }
    }

    private var intentionStep: some View {
        VStack(spacing: 20) {
            ReclaimMascotView(state: .focus, size: 150)

            Text("Lock in.")
                .font(ReclaimTypography.hero)
                .foregroundStyle(ReclaimColors.text)
                .multilineTextAlignment(.center)

            Text("Reclaim est la petite friction qui t'aide à reprendre ta vie en main, sans culpabilité et sans usine à gaz.")
                .font(.headline)
                .foregroundStyle(ReclaimColors.muted)
                .multilineTextAlignment(.center)
        }
    }

    private var ageStep: some View {
        VStack(spacing: 20) {
            Text("On part de toi.")
                .font(ReclaimTypography.hero)
                .foregroundStyle(ReclaimColors.text)
                .multilineTextAlignment(.center)

            Text("Ton âge et ta moyenne quotidienne nous donnent une baseline simple. Tu peux la lire dans Réglages iOS > Temps d'écran.")
                .font(.headline)
                .foregroundStyle(ReclaimColors.muted)
                .multilineTextAlignment(.center)

            ReclaimCard {
                VStack(spacing: 24) {
                    ReclaimDurationPicker(
                        title: "Ton âge",
                        values: Array(13...100),
                        suffix: "ans",
                        selection: $age
                    )

                    Divider()

                    ReclaimDurationPicker(
                        title: "Moyenne quotidienne",
                        values: Array(stride(from: 15, through: 1_200, by: 15)),
                        suffix: "min",
                        step: 15,
                        selection: $dailyMinutes
                    )
                }
            }
        }
    }

    private var authorizationStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.shield.checkmark")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(ReclaimColors.primary)
                .frame(width: 116, height: 116)
                .background(ReclaimColors.primary.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            Text("Autorise Screen Time")
                .font(ReclaimTypography.hero)
                .foregroundStyle(ReclaimColors.text)
                .multilineTextAlignment(.center)

            Text("Si tu refuses, tu pourras continuer mais tu n'auras pas accès à toutes les fonctionnalités de Reclaim.")
                .font(.headline)
                .foregroundStyle(ReclaimColors.muted)
                .multilineTextAlignment(.center)

            ReclaimCard {
                VStack(spacing: 14) {
                    Text(viewModel.screenTimeAuthorization.label)
                        .font(ReclaimTypography.cardTitle)
                        .foregroundStyle(ReclaimColors.text)

                    ReclaimButton(
                        title: viewModel.screenTimeAuthorization.isAuthorized ? "Autorisation active" : "Autoriser Screen Time",
                        symbol: viewModel.screenTimeAuthorization.isAuthorized ? "checkmark" : "shield.fill"
                    ) {
                        guard !viewModel.screenTimeAuthorization.isAuthorized else { return }
                        isRequestingAuthorization = true
                        Task {
                            await viewModel.requestScreenTimeAuthorization()
                            isRequestingAuthorization = false
                        }
                    }
                    .disabled(isRequestingAuthorization || viewModel.screenTimeAuthorization.isAuthorized)
                }
            }
        }
    }

    private var appSelectionStep: some View {
        VStack(spacing: 18) {
            Text("Choisis tes apps")
                .font(ReclaimTypography.hero)
                .foregroundStyle(ReclaimColors.text)
                .multilineTextAlignment(.center)

            Text("Ces apps formeront ton groupe principal : Reclaim les surveillera pour le blocage scroll et les blocages immédiats.")
                .font(.headline)
                .foregroundStyle(ReclaimColors.muted)
                .multilineTextAlignment(.center)

            if viewModel.screenTimeAuthorization.isAuthorized {
                RealAppSelectionView()
            } else {
                ReclaimCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sélection indisponible sans autorisation")
                            .font(ReclaimTypography.cardTitle)
                            .foregroundStyle(ReclaimColors.text)
                        Text("Tu pourras autoriser Screen Time puis choisir tes apps depuis Paramètres.")
                            .font(.subheadline)
                            .foregroundStyle(ReclaimColors.muted)
                    }
                }
            }
        }
    }

    private var projectionStep: some View {
        VStack(spacing: 18) {
            Text("Ta projection.")
                .font(ReclaimTypography.hero)
                .foregroundStyle(ReclaimColors.text)
                .multilineTextAlignment(.center)

            Text(projectionPhaseText.isEmpty ? projectionText : projectionPhaseText)
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(ReclaimColors.text)
                .multilineTextAlignment(.center)
                .frame(minHeight: 92)

            ReclaimCard {
                VStack(spacing: 16) {
                    LifeProjectionMatrix(
                        visible: visibleLifeDots,
                        lived: livedLifeDots,
                        phone: phoneLifeDots,
                        total: lifeExpectancy
                    )

                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var projectionText: String {
        let years = Int(projectedPhoneYears.rounded())
        return "Estimation initiale : à \(age) ans, si ton usage moyen reste autour de \(formatMinutes(dailyMinutes)) par jour, tu pourrais passer environ \(years) ans sur ton téléphone d'ici \(lifeExpectancy) ans. Reclaim sert à récupérer une partie de ce temps."
    }

    private var projectedPhoneYears: Double {
        Double(remainingLifeYears * 365 * dailyMinutes) / 525_600
    }

    private var projectionDotTarget: Int {
        min(max(0, Int(projectedPhoneYears.rounded())), max(remainingLifeYears, 1))
    }

    private var primaryButtonTitle: String {
        switch step {
        case 0: "Je veux reprendre ma vie en main"
        case 1: "Continuer"
        case 2: "Choisir mes apps"
        case 3: "Voir ma projection"
        default: "Entrer dans Reclaim"
        }
    }

    private var primaryButtonSymbol: String {
        step == totalSteps - 1 ? "arrow.right" : "checkmark"
    }

    private var canLeaveAuthorizationStep: Bool {
        viewModel.baselineSettings.hasRequestedScreenTimeAuthorization || viewModel.screenTimeAuthorization.isAuthorized
    }

    private var canShowPrimaryButton: Bool {
        step != totalSteps - 1 || isProjectionComplete
    }

    private var canTapPrimaryButton: Bool {
        if step == 2 && !canLeaveAuthorizationStep { return false }
        if step == totalSteps - 1 && !isProjectionComplete { return false }
        return true
    }

    private func primaryAction() {
        if step == 1 {
            viewModel.baselineSettings.age = age
            viewModel.baselineSettings.baselineDailyScreenMinutes = dailyMinutes
        }

        if step < totalSteps - 1 {
            step += 1
            return
        }

        viewModel.completeBaselineOnboarding(
            age: age,
            dailyScreenMinutes: dailyMinutes
        )
    }

    private func animateDots() {
        animatedDots = 0
        visibleLifeDots = 0
        livedLifeDots = 0
        phoneLifeDots = 0
        isProjectionComplete = false
        projectionPhaseText = "On affiche ta ligne de vie jusqu'à \(lifeExpectancy) ans."

        for index in 1...lifeExpectancy {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.045) {
                visibleLifeDots = index
            }
        }

        let livedStart = Double(lifeExpectancy) * 0.06 + 1.30
        DispatchQueue.main.asyncAfter(deadline: .now() + livedStart) {
            projectionPhaseText = "Ces \(age) premières années sont déjà vécues."
            for index in 1...age {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.045) {
                    livedLifeDots = index
                }
            }
        }

        let phoneStart = livedStart + Double(age) * 0.045 + 2.3
        DispatchQueue.main.asyncAfter(deadline: .now() + phoneStart) {
            projectionPhaseText = "À \(formatMinutes(dailyMinutes)) par jour, environ \(projectionDotTarget) ans pourraient partir dans ton téléphone."
            guard projectionDotTarget > 0 else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isProjectionComplete = true
                }
                return
            }
            for index in 1...projectionDotTarget {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.085) {
                    phoneLifeDots = index
                    if index == projectionDotTarget {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                            projectionPhaseText = "Reclaim sert à récupérer une partie de ce temps, petit à petit."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                                isProjectionComplete = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        "\(minutes / 60)h\(String(format: "%02d", minutes % 60))"
    }
}

private struct LifeProjectionMatrix: View {
    let visible: Int
    let lived: Int
    let phone: Int
    let total: Int

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 10), spacing: 10) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(color(for: index))
                    .frame(width: 17, height: 17)
                    .opacity(index < visible ? 1 : 0)
                    .scaleEffect(index < visible ? 1 : 0.65)
                    .shadow(color: color(for: index).opacity(isPhoneYear(index) ? 0.24 : 0), radius: 8, x: 0, y: 4)
                    .animation(.easeOut(duration: 0.28).delay(Double(index) * 0.006), value: visible)
                    .animation(.spring(response: 0.24, dampingFraction: 0.76).delay(Double(index) * 0.005), value: lived)
                    .animation(.spring(response: 0.26, dampingFraction: 0.70).delay(Double(index) * 0.006), value: phone)
            }
        }
    }

    private func color(for index: Int) -> Color {
        if isPhoneYear(index) {
            return ReclaimColors.primary
        }
        if index < lived {
            return ReclaimColors.muted.opacity(0.42)
        }
        return ReclaimColors.border.opacity(0.72)
    }

    private func isPhoneYear(_ index: Int) -> Bool {
        index >= lived && index < min(total, lived + phone)
    }
}
