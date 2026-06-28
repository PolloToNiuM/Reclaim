import SwiftUI

struct ReclaimCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat

    init(padding: CGFloat = 20, cornerRadius: CGFloat = 30, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ReclaimColors.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ReclaimColors.border, lineWidth: 1)
            }
            .shadow(color: ReclaimColors.text.opacity(0.05), radius: 20, x: 0, y: 10)
    }
}
