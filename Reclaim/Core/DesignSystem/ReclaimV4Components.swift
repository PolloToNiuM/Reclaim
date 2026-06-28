import SwiftUI
import UIKit

struct ReclaimScreenHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(ReclaimTypography.title)
                    .foregroundStyle(ReclaimColors.text)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ReclaimColors.muted)
                }
            }

            Spacer()

            trailing
        }
        .padding(.top, 12)
    }
}

extension ReclaimScreenHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = EmptyView()
    }
}

struct ReclaimIconButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(ReclaimColors.primary)
                .clipShape(Circle())
                .shadow(color: ReclaimColors.primary.opacity(0.22), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct ReclaimDurationPicker: View {
    let title: String
    let values: [Int]
    let suffix: String
    var step = 1
    @Binding var selection: Int
    @State private var dragStartSelection: Int?
    @State private var dragTranslation: CGFloat = 0
    @State private var inertiaToken = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(ReclaimTypography.cardTitle)
                    .foregroundStyle(ReclaimColors.text)
                Spacer()
                Text(displayText(for: selection, includeSuffix: true))
                    .font(.headline.weight(.black))
                    .foregroundStyle(ReclaimColors.text)
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                let centerX = width / 2
                let visualOffset = dragStartSelection == nil ? 0 : dragTranslation
                let anchorSelection = dragStartSelection ?? selection

                ZStack {
                    ForEach(visibleValues, id: \.self) { value in
                        let x = centerX + CGFloat(value - anchorSelection) / CGFloat(stepSize) * tickSpacing + visualOffset
                        if x > -40 && x < width + 40 {
                            VStack(spacing: 14) {
                                if labelOpacity(for: value, x: x, centerX: centerX) > 0.01 {
                                    Text(labelText(for: value))
                                        .font(.system(size: value == selection ? 58 : 30, weight: .black, design: .rounded))
                                        .foregroundStyle(value == selection ? ReclaimColors.text : ReclaimColors.muted.opacity(0.62))
                                        .opacity(labelOpacity(for: value, x: x, centerX: centerX))
                                        .frame(height: 62)
                                } else {
                                    Color.clear.frame(height: 62)
                                }

                                Capsule()
                                    .fill(value == selection ? ReclaimColors.primary : ReclaimColors.border)
                                    .frame(width: value == selection ? 8 : 4, height: tickHeight(for: value))
                            }
                            .position(x: x, y: 55)
                        }
                    }

                    VStack(spacing: 7) {
                        Capsule()
                            .fill(ReclaimColors.primary)
                            .frame(width: 9, height: 46)
                        Triangle()
                            .fill(ReclaimColors.primary)
                            .frame(width: 26, height: 18)
                    }
                    .position(x: centerX, y: 92)
                }
                .clipped()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            inertiaToken = UUID()
                            if dragStartSelection == nil {
                                dragStartSelection = selection
                            }

                            let start = dragStartSelection ?? selection
                            dragTranslation = value.translation.width
                            let offset = Int((-value.translation.width / tickSpacing).rounded()) * stepSize
                            let newSelection = min(max(start + offset, minValue), maxValue)
                            if newSelection != selection {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selection = newSelection
                            }
                        }
                        .onEnded { value in
                            let token = UUID()
                            inertiaToken = token
                            let predictedExtra = max(min(value.predictedEndTranslation.width - value.translation.width, tickSpacing * 10), -tickSpacing * 10)
                            let inertialOffset = Int((-(value.translation.width + predictedExtra) / tickSpacing).rounded()) * stepSize
                            let start = dragStartSelection ?? selection
                            let target = min(max(start + inertialOffset, minValue), maxValue)
                            if target != selection {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            let finalTranslation = -CGFloat(target - start) / CGFloat(stepSize) * tickSpacing
                            let crossedTicks = max(1, abs(target - selection) / stepSize)
                            let duration = min(0.72, max(0.28, Double(crossedTicks) * 0.055))

                            withAnimation(.timingCurve(0.16, 0.82, 0.20, 1.0, duration: duration)) {
                                dragTranslation = finalTranslation
                            }

                            animateSelection(from: selection, to: target, duration: duration, token: token)

                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                guard inertiaToken == token else { return }
                                selection = target
                                dragStartSelection = nil
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    dragTranslation = 0
                                }
                            }
                        }
                )
            }
            .frame(height: 128)
        }
    }

    private var minValue: Int {
        values.min() ?? 1
    }

    private var maxValue: Int {
        values.max() ?? 60
    }

    private var visibleValues: [Int] {
        let lower = max(minValue, selection - stepSize * 24)
        let upper = min(maxValue, selection + stepSize * 24)
        return Array(stride(from: lower, through: upper, by: stepSize))
    }

    private var tickSpacing: CGFloat {
        42
    }

    private var stepSize: Int {
        max(1, step)
    }

    private func labelText(for value: Int) -> String {
        if value == selection { return displayText(for: value, includeSuffix: false) }
        return shouldShowReferenceLabel(for: value) ? displayText(for: value, includeSuffix: false) : ""
    }

    private func labelOpacity(for value: Int, x: CGFloat, centerX: CGFloat) -> Double {
        if value == selection { return 1 }
        guard shouldShowReferenceLabel(for: value) else { return 0 }
        let distanceFromSelection = abs(x - centerX)
        if abs(value - selection) <= stepSize { return 0 }
        if distanceFromSelection < 76 { return 0 }
        return 1
    }

    private func animateSelection(from start: Int, to target: Int, duration: Double, token: UUID) {
        guard start != target else { return }
        let direction = target > start ? stepSize : -stepSize
        let values = stride(from: start + direction, through: target, by: direction).map { $0 }
        guard !values.isEmpty else { return }

        for (index, value) in values.enumerated() {
            let progress = Double(index + 1) / Double(values.count)
            let easedProgress = 1 - pow(1 - progress, 2.2)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * easedProgress) {
                guard inertiaToken == token else { return }
                if selection != value {
                    selection = value
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }

    private func tickHeight(for value: Int) -> CGFloat {
        if value == selection { return 46 }
        if shouldShowReferenceLabel(for: value) { return 36 }
        return 22
    }

    private func shouldShowReferenceLabel(for value: Int) -> Bool {
        stepSize >= 15 ? value % 60 == 0 : value % 5 == 0
    }

    private func displayText(for value: Int, includeSuffix: Bool) -> String {
        guard suffix == "min", maxValue >= 120 else {
            return includeSuffix ? "\(value) \(suffix)" : "\(value)"
        }

        let hours = value / 60
        let minutes = value % 60
        let formatted = minutes == 0 ? "\(hours)h" : "\(hours)h\(String(format: "%02d", minutes))"
        return includeSuffix ? formatted : formatted
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

struct ReclaimSegmentedPicker: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        selection = option
                    }
                } label: {
                    HStack(spacing: 7) {
                        if selection == option {
                            Image(systemName: "checkmark")
                        }
                        Text(option)
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(selection == option ? ReclaimColors.primary : ReclaimColors.cream)
                    .foregroundStyle(selection == option ? .white : ReclaimColors.muted)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ReclaimBarChart: View {
    let values: [Double]
    let labels: [String]
    var color = ReclaimColors.secondary

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(value > 0 ? color.opacity(0.48) : ReclaimColors.border.opacity(0.72))
                        .frame(height: max(8, CGFloat(value) * 92))

                    Text(labels.indices.contains(index) ? labels[index] : "")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(ReclaimColors.muted.opacity(0.72))
                }
            }
        }
        .frame(height: 126, alignment: .bottom)
    }
}

struct ReclaimDotMatrix: View {
    let filled: Int
    let total: Int

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 10), spacing: 10) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 16, height: 16)
                    .scaleEffect(index < filled ? 1 : 0.82)
                    .shadow(color: dotColor(for: index).opacity(index < filled ? 0.18 : 0), radius: 8, x: 0, y: 4)
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.72).delay(Double(index) * 0.006),
                        value: filled
                    )
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index < filled {
            return ReclaimColors.primary
        }
        return ReclaimColors.border
    }
}
