import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel
    @State private var metric = "Temps récupéré"
    @State private var period = "Semaine"
    @State private var animatedRecoveredYearDots = 0
    private let metricOptions = ["Temps d'écran", "Temps récupéré"]
    private let periodOptions = ["Semaine", "Mois"]

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ReclaimScreenHeader(title: "Progrès", subtitle: "Moins de bruit, plus de temps qui revient.")

                    if !viewModel.canEstimateScreenTime {
                        unavailableCard
                    } else if !viewModel.hasReclaimScreenTimeData {
                        noDataCard
                    } else {
                        lifetimeCard
                        totalRecoveredCard
                        progressCard
                    }
                }
                .padding(20)
                .padding(.bottom, 18)
            }
        }
        .onAppear {
            animateRecoveredYears()
        }
    }

    private var unavailableCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "shield.slash.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(ReclaimColors.primary)
                    .frame(width: 72, height: 72)
                    .background(ReclaimColors.primary.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Text("Indisponible sans autorisation")
                    .font(ReclaimTypography.section)
                    .foregroundStyle(ReclaimColors.text)

                Text("Les visualisations de temps d'écran et les projections de vie récupérée ont besoin de Screen Time. Tu peux l'activer dans Paramètres.")
                    .font(.subheadline)
                    .foregroundStyle(ReclaimColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var noDataCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(ReclaimColors.primary)
                    .frame(width: 72, height: 72)
                    .background(ReclaimColors.primary.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Text("Pas encore de données")
                    .font(ReclaimTypography.section)
                    .foregroundStyle(ReclaimColors.text)

                Text("Reclaim affichera le temps d'écran et le temps récupéré après les premières données observées sur tes apps surveillées.")
                    .font(.subheadline)
                    .foregroundStyle(ReclaimColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var lifetimeCard: some View {
        ReclaimCard {
            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Projection de vie")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ReclaimColors.muted)
                        Text("\(projectedRecoveredYearText) années projetées d'être récupérées")
                            .font(ReclaimTypography.cardTitle)
                            .foregroundStyle(ReclaimColors.text)
                    }

                    Spacer()

                    ReclaimMascotView(state: .success, size: 72)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(projectedRecoveredYearText)
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .foregroundStyle(ReclaimColors.primary)
                    Text("ans")
                        .font(.title2.bold())
                        .foregroundStyle(ReclaimColors.primaryDeep)
                }

                Text("Gris : déjà vécu. Orange clair : sommeil estimé. Rouge : temps projeté sur le téléphone. Orange : temps que Reclaim t'aide à récupérer.")
                    .font(.subheadline)
                    .foregroundStyle(ReclaimColors.muted)
                    .multilineTextAlignment(.center)

                StatsLifeProjectionMatrix(
                    age: viewModel.baselineSettings.age,
                    sleepYears: projectedSleepYears,
                    phoneYears: projectedPhoneYears,
                    recoveredYears: animatedRecoveredYearDots,
                    total: viewModel.baselineSettings.lifeExpectancy
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var totalRecoveredCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Total de temps récupéré")
                    .font(ReclaimTypography.section)
                    .foregroundStyle(ReclaimColors.text)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(max(0, viewModel.recoveredMinutes / 60))")
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .foregroundStyle(ReclaimColors.primary)
                    Text("h")
                        .font(.title2.bold())
                        .foregroundStyle(ReclaimColors.primary)
                    Text("\(viewModel.recoveredMinutes % 60)m")
                        .font(.title2.bold())
                        .foregroundStyle(ReclaimColors.primary)
                }

                Text("Baseline actuelle: \(viewModel.baselineSettings.baselineDailyScreenMinutes) min/jour avant Reclaim.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ReclaimColors.muted)

                ProgressView(value: min(Double(max(0, viewModel.recoveredMinutes)), 1500), total: 1500)
                    .tint(ReclaimColors.primary)
                    .scaleEffect(x: 1, y: 2.4, anchor: .center)
            }
        }
    }

    private var progressCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(period == "Semaine" ? "Progrès récents" : "Mois par mois")
                        .font(ReclaimTypography.section)
                        .foregroundStyle(ReclaimColors.text)
                    Spacer()
                }

                ReclaimSegmentedPicker(options: periodOptions, selection: $period)
                ReclaimSegmentedPicker(options: metricOptions, selection: $metric)

                HStack(spacing: 34) {
                    MetricColumn(title: "Moy. quotidienne", value: dailyAverageText)
                    MetricColumn(title: period == "Semaine" ? "Cette semaine" : "Ce mois", value: periodTotalText)
                }

                ReclaimBarChart(
                    values: chartValues,
                    labels: period == "Semaine" ? ["D", "L", "M", "M", "J", "V", "S"] : ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"],
                    color: ReclaimColors.primary
                )
            }
        }
    }

    private var projectedRecoveredYearText: String {
        "\(Int(projectedRecoveredYears.rounded()))"
    }

    private func animateRecoveredYears() {
        animatedRecoveredYearDots = 0
        let target = min(Int(projectedRecoveredYears.rounded(.down)), max(viewModel.baselineSettings.remainingLifeYears, 1))
        guard target > 0 else { return }
        for index in 1...target {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.02) {
                animatedRecoveredYearDots = index
            }
        }
    }

    private var projectedPhoneYears: Int {
        let remainingYears = viewModel.baselineSettings.remainingLifeYears
        let years = Double(remainingYears * 365 * viewModel.baselineSettings.baselineDailyScreenMinutes) / 525_600
        return min(remainingYears, max(0, Int(years.rounded())))
    }

    private var projectedSleepYears: Int {
        let remainingYears = viewModel.baselineSettings.remainingLifeYears
        return min(remainingYears, max(0, Int((Double(remainingYears) / 3.0).rounded())))
    }

    private var projectedRecoveredYears: Double {
        let remainingYears = viewModel.baselineSettings.remainingLifeYears
        let projectedMinutes = Double(viewModel.recoveredMinutes * 365 * remainingYears)
        return projectedMinutes / 525_600
    }

    private var dailyAverageText: String {
        if metric == "Temps d'écran" {
            return "\(viewModel.estimatedScreenMinutesToday)m"
        }
        return "\(max(0, viewModel.recoveredMinutes))m"
    }

    private var periodTotalText: String {
        let multiplier = period == "Semaine" ? 7 : 30
        let minutes = metric == "Temps d'écran"
            ? viewModel.estimatedScreenMinutesToday * multiplier
            : viewModel.recoveredMinutes * multiplier
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private var chartValues: [Double] {
        if period == "Semaine" {
            return metric == "Temps d'écran"
                ? [0.74, 0.68, 0.64, 0.58, 0.52, 0.46, max(0.08, Double(viewModel.estimatedScreenMinutesToday) / Double(max(viewModel.baselineSettings.baselineDailyScreenMinutes, 1)))]
                : [0.06, 0.10, 0.14, 0.18, 0.24, 0.36, min(1, Double(max(viewModel.recoveredMinutes, 1)) / 90)]
        }

        return metric == "Temps d'écran"
            ? [0.80, 0.76, 0.72, 0.68, 0.64, 0.58, 0.54, 0.50, 0.48, 0.46, 0.44, 0.42]
            : [0.04, 0.05, 0.06, 0.08, 0.12, 0.18, 0.24, 0.30, 0.36, 0.44, 0.52, 0.60]
    }
}

private struct MetricColumn: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ReclaimColors.muted)
            Text(value)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(ReclaimColors.primary)
        }
    }
}

private struct StatsLifeProjectionMatrix: View {
    let age: Int
    let sleepYears: Int
    let phoneYears: Int
    let recoveredYears: Int
    let total: Int

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 10), spacing: 10) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(color(for: index))
                    .frame(width: 17, height: 17)
                    .scaleEffect(index < recoveredUpperBound ? 1.08 : 1)
                    .shadow(color: color(for: index).opacity(index < recoveredUpperBound ? 0.20 : 0), radius: 8, x: 0, y: 4)
                    .animation(.spring(response: 0.28, dampingFraction: 0.72).delay(Double(index) * 0.004), value: recoveredYears)
            }
        }
    }

    private var sleepUpperBound: Int {
        min(total, max(age, 0) + max(sleepYears, 0))
    }

    private var phoneUpperBound: Int {
        min(total, sleepUpperBound + max(phoneYears, 0))
    }

    private var recoveredUpperBound: Int {
        min(phoneUpperBound, sleepUpperBound + max(recoveredYears, 0))
    }

    private func color(for index: Int) -> Color {
        if index < max(age, 0) {
            return ReclaimColors.muted.opacity(0.42)
        }
        if index < recoveredUpperBound {
            return ReclaimColors.primary
        }
        if index < sleepUpperBound {
            return ReclaimColors.primarySoft.opacity(0.78)
        }
        if index < phoneUpperBound {
            return ReclaimColors.dangerVivid
        }
        return ReclaimColors.border.opacity(0.78)
    }
}
