import Foundation

extension Creature {
    func doKill(context: CommandContext) {
        guard let victim = context.creature1 else {
            send("Кого Вы хотите убить?")
            return
        }

        if isGodMode() {
            logIntervention("\(nameNominative.full) атакует \(victim.nameAccusative.full)")
        }
        
        guard startFighting(victim: victim) else { return }
        lagSet(pulseViolence)

        hitOnce(victim: victim)
    }
}
