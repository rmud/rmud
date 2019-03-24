import Foundation

extension Player {
    func stopWatching() -> Bool {
        //XXX ещё подобное действие выпоняется в make_pronpt() (act.informative.cpp)
        //т.к. в тот момент act() не сработает
        guard let watching = watching else {
            return false
        }
        act("Вы прекратили наблюдать за состоянием 2р.",
            .toSleeping, .toCreature(creature), .excludingCreature(watching))
        self.watching = nil
        return true
    }
}
