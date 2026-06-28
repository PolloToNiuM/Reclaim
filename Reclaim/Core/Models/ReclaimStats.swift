import Foundation

struct ReclaimStats: Equatable, Codable {
    var protectedSecondsToday: Int = 0
    var sessions: Int = 0
    var triggeredBlocks: Int = 0
    var unlockAttempts: Int = 0
    var successfulChallenges: Int = 0

    var protectedMinutes: Int {
        max(0, protectedSecondsToday / 60)
    }
}
