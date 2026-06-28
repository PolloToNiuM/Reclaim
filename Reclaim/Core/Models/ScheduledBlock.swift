import Foundation

struct ScheduledBlock: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var start: Date
    var end: Date
    var days: Set<Weekday>
    var usesStrictMode: Bool

    var scheduleSummary: String {
        let dayText = days.sorted().map(\.shortLabel).joined(separator: " ")
        return "\(dayText) | \(Self.timeFormatter.string(from: start)) - \(Self.timeFormatter.string(from: end))"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

enum Weekday: Int, CaseIterable, Comparable, Identifiable, Codable {
    case monday = 1
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .monday: "L"
        case .tuesday: "M"
        case .wednesday: "M"
        case .thursday: "J"
        case .friday: "V"
        case .saturday: "S"
        case .sunday: "D"
        }
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension DateComponents {
    var minutesOfDay: Int {
        (hour ?? 0) * 60 + (minute ?? 0)
    }
}
