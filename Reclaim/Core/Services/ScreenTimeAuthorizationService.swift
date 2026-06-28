import FamilyControls
import Foundation

enum ScreenTimeAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case denied
    case failed(String)

    var isAuthorized: Bool {
        self == .authorized
    }

    var label: String {
        switch self {
        case .notDetermined:
            "Permission non configuree"
        case .authorized:
            "Permission active"
        case .denied:
            "Permission refusée"
        case .failed:
            "Permission indisponible"
        }
    }
}

struct ScreenTimeAuthorizationService {
    func currentState() -> ScreenTimeAuthorizationState {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .approved:
            return .authorized
        @unknown default:
            return .failed("État d'autorisation inconnu.")
        }
    }

    func requestAuthorization() async -> ScreenTimeAuthorizationState {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            return currentState()
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
