import Foundation

struct StrictModeSettings: Equatable, Codable {
    var allowsPauses = true
    var pauseDelay: PauseDelay = .ten
    var maxPauseDuration: PauseDuration = .five
    var requiresChallenge = true
    var challengeDifficulty: ChallengeDifficulty = .medium
}

enum PauseDelay: Int, CaseIterable, Identifiable, Codable {
    case none = 0
    case ten = 10
    case thirty = 30
    case sixty = 60

    var id: Int { rawValue }
    var label: String { rawValue == 0 ? "0s" : "\(rawValue)s" }
}

enum PauseDuration: Int, CaseIterable, Identifiable, Codable {
    case three = 3
    case five = 5
    case ten = 10

    var id: Int { rawValue }
    var label: String { "\(rawValue) min" }
}

enum ChallengeDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .easy: "Facile"
        case .medium: "Moyen"
        case .hard: "Difficile"
        }
    }
}
