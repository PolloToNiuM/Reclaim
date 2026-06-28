import Foundation

enum BlockMode: String, CaseIterable, Identifiable {
    case immediate
    case scheduled
    case sessionLimit
    case strict

    var id: String { rawValue }

    var title: String {
        switch self {
        case .immediate: "Blocage immédiat"
        case .scheduled: "Blocages planifiés"
        case .sessionLimit: "Limite de session"
        case .strict: "Mode strict"
        }
    }

    var subtitle: String {
        switch self {
        case .immediate: "Bloque tes apps maintenant pendant une durée choisie."
        case .scheduled: "Prépare des horaires ; l'enforcement réel arrive par étapes."
        case .sessionLimit: "Crée une friction après une longue session de scroll."
        case .strict: "Rends les pauses et modifications plus difficiles."
        }
    }

    var symbol: String {
        switch self {
        case .immediate: "bolt.fill"
        case .scheduled: "calendar.badge.clock"
        case .sessionLimit: "hourglass"
        case .strict: "lock.shield.fill"
        }
    }
}
