import SwiftUI

enum ReclaimTypography {
    static let hero = Font.system(size: 40, weight: .black, design: .rounded)
    static let title = Font.system(.largeTitle, design: .rounded).weight(.black)
    static let section = Font.system(.title2, design: .rounded).weight(.bold)
    static let cardTitle = Font.system(.headline, design: .rounded).weight(.bold)
    static let body = Font.system(.body, design: .rounded)
}
