import FamilyControls
import Foundation

struct FamilyActivitySelectionStore {
    var selection = FamilyActivitySelection()

    var isEmpty: Bool {
        selection.applicationTokens.isEmpty &&
        selection.categoryTokens.isEmpty &&
        selection.webDomainTokens.isEmpty
    }

    var itemCount: Int {
        selection.applicationTokens.count +
        selection.categoryTokens.count +
        selection.webDomainTokens.count
    }
}
