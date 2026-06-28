import SwiftUI

struct ReclaimBadge: View {
    let text: String
    var color = ReclaimColors.mint
    var textColor: Color? = nil

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .rounded).weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.14))
            .foregroundStyle(textColor ?? color)
            .clipShape(Capsule())
    }
}
