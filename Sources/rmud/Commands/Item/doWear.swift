import Foundation

extension Creature {
    func doWear(context: CommandContext) {
        guard !context.items1.isEmpty else {
            send("Что Вы хотите надеть?")
            return
        }
        
        for item in context.items1 {
            wear(item: item, isSilent: false)
        }
    }
}
