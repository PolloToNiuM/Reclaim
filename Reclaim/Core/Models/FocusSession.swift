import Foundation

enum FocusSessionState: Equatable {
    case inactive
    case active
    case temporaryUnlock(until: Date)

    var label: String {
        switch self {
        case .inactive:
            "Aucune session active"
        case .active:
            "Session active"
        case .temporaryUnlock:
            "Pause débloquée temporairement"
        }
    }
}

struct FocusSession: Identifiable, Equatable {
    let id = UUID()
    let startedAt: Date
    let duration: TimeInterval
    var state: FocusSessionState = .active

    var endsAt: Date {
        startedAt.addingTimeInterval(duration)
    }
}
