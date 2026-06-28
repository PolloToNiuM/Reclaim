import SwiftUI

struct ReclaimButton: View {
    let title: String
    let symbol: String
    var isPrimary = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isPrimary ? ReclaimColors.primary : ReclaimColors.card)
                .foregroundStyle(isPrimary ? .white : ReclaimColors.text)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(isPrimary ? .clear : ReclaimColors.border, lineWidth: 1)
                }
                .shadow(color: (isPrimary ? ReclaimColors.primary : ReclaimColors.text).opacity(0.14), radius: 14, x: 0, y: 7)
        }
        .buttonStyle(.plain)
    }
}
