import Foundation

extension Creature {
    func putToLinkDeadState() -> Bool {
        guard let player = player else { return false }
        guard !isGodMode() else { return false }
        if !isFighting && !player.isNoQuit && !isCharmed() &&
                !position.isDyingOrDead && !isAffected(by: .poison) {
            return true
        }
        return false
    }
    
//    func restoreFromLinkDeadState() -> Bool {
//        guard let player = player else { return false }
//        guard player.isMortalAndLinkDead else { return false }
//
//        return true
//    }
    
    func returnToOriginalCreature() {
        // FIXME: port do_return
    }
}
