extension Creature {
    func doWield(context: CommandContext) {
        guard canUseWeapons else {
            send("Вы не способны пользоваться оружием.")
            return
        }
        
        guard let weapon = context.item1 else {
            send("Чем Вы хотите вооружиться?")
            return
        }
        
        guard weapon.wearFlags.contains(.wield) else {
            if weapon.wearFlags.contains(.twoHand) {
                act("Одной рукой @1т сражаться нельзя.", .to(self), .item(weapon))
            } else {
                act("Вооружиться @1т нельзя.", .to(self), .item(weapon))
            }
            return
        }
        
        performWearOrHold(item: weapon, positions: [.wield], isSilent: false)
    }
}
