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
        
        if item.isLight() {
            performWearOrHold(item: item, positions: [.light], isSilent: false)
        } else if !item.wearFlags.contains(.hold) &&
                !item.isWand() &&
                !item.isStaff() &&
                !item.isScroll() &&
                !item.isPotion() {
            act("@1в держать в руке нельзя.", .to(self), .item(item))
        } else {
            performWearOrHold(item: item, positions: [.hold], isSilent: false)
        }
    }
}
