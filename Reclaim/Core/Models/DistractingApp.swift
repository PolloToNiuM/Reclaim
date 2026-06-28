import Foundation

struct DistractingApp: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: String
    let symbol: String
    var isSelected: Bool
}
