import SwiftUI
import UIKit

struct ReclaimMascotView: View {
    let state: ReclaimMascotState
    var size: CGFloat = 132

    var body: some View {
        ZStack {
            Circle()
                .fill(auraColor.opacity(0.18))
                .frame(width: size * 0.95, height: size * 0.95)
                .blur(radius: 12)

            if let image = mascotImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            } else {
                fallbackMascot
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Mascotte écureuil horloger Reclaim")
    }

    private var auraColor: Color {
        switch state {
        case .idle: ReclaimColors.primary
        case .focus: ReclaimColors.secondary
        case .blocked: ReclaimColors.primaryDeep
        case .temporaryUnlock: ReclaimColors.accent
        case .success: ReclaimColors.warning
        }
    }

    private var mascotImage: UIImage? {
        let names = [
            "Gemini_Generated_Image_73pw2c73pw2c73pw",
            "Gemini_Generated_Image_pkmzdcpkmzdcpkmz",
            "Gemini_Generated_Image_ugf2paugf2paugf2"
        ]

        for name in names {
            if let image = UIImage(named: name) {
                return image
            }

            if let url = Bundle.main.url(forResource: name, withExtension: "png"),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }

            if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets"),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }

        return nil
    }

    private var fallbackMascot: some View {
        ZStack {
            Circle()
                .fill(ReclaimColors.primary.opacity(0.22))
                .frame(width: size * 0.82, height: size * 0.82)

            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(ReclaimColors.primary)
        }
    }
}
