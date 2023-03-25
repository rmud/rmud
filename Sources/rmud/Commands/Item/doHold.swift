extension Creature {
    func doHold(context: CommandContext) {
        guard canUseWeapons else {
            send("Вы не умеете ничего держать.")
            return
        }

        guard let item = context.item1 else {
            send("Что Вы хотите взять во вторую руку?")
            return
        }
        
        if item.hasType(.light) {
            performWear(item: item, positions: [.light], isSilent: false)
        } else if !item.wearFlags.contains(.hold) &&
                !item.hasType(.wand) &&
                !item.hasType(.staff) &&
                !item.hasType(.scroll) &&
                    !item.hasType(.potion) {
            act("@1в держать в руке нельзя.", .to(self), .item(item))
        } else {
            performWear(item: item, positions: [.hold], isSilent: false)
        }
    }
}
