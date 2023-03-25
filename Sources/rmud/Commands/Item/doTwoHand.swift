extension Creature {
    func doTwoHand(context: CommandContext) {
        guard canUseWeapons else {
            send("Вы не способны пользоваться оружием.")
            return
        }
        
        guard let weapon = context.item1 else {
            send("Что Вы хотите взять в обе руки?")
            return
        }
        
        guard weapon.wearFlags.contains(.twoHand) else {
            if weapon.wearFlags.contains(.wield) {
                act("Двумя руками @1т сражаться нельзя.", .to(self), .item(weapon))
            } else {
                act("Вооружиться @1т нельзя.", .to(self), .item(weapon))
            }
            return
        }
        
        performWear(item: weapon, positions: [.twoHand], isSilent: false)
    }
}
