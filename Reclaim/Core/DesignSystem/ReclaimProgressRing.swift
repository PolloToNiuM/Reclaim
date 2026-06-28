import SwiftUI

struct ReclaimProgressRing<Content: View>: View {
    let progress: Double
    let content: Content

    init(progress: Double, @ViewBuilder content: () -> Content) {
        self.progress = progress
        self.content = content()
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(ReclaimColors.panelStrong, lineWidth: 18)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(ReclaimColors.mint, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)

            content
        }
    }
}
