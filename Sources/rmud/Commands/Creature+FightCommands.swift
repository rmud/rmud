import Foundation

extension Creature {
    func doKill(context: CommandContext) {
        guard let victim = context.creature1 else {
            send("Кого Вы хотите убить?")
            return
        }
        
        guard startFight(victim: victim) else { return }

        if isGodMode() {
            logIntervention("\(nameNominative.full) атакует \(victim.nameAccusative.full)")
        }
        
        send("Вы начали бой с \(victim.nameInstrumental.full).")
        lagSet(pulseViolence)
    }
}
