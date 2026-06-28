import SwiftUI

struct ReclaimBackground: View {
    var body: some View {
        ZStack {
            ReclaimColors.background

            RadialGradient(
                colors: [ReclaimColors.secondary.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 280
            )

            RadialGradient(
                colors: [ReclaimColors.primary.opacity(0.13), .clear],
                center: .bottomLeading,
                startRadius: 40,
                endRadius: 340
            )
        }
        .ignoresSafeArea()
    }
}
