import FamilyControls
import Foundation
import ManagedSettings

final class AppShieldService {
    private let store = ManagedSettingsStore()
    private(set) var isShieldActive = false

    func applyShield(selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
        isShieldActive = true
    }

    func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        isShieldActive = false
    }
}
