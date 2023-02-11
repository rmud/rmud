extension Creature {
    func doInventory(context: CommandContext) {
        guard !carrying.isEmpty else {
            send("У Вас в руках ничего нет.")
            return
        }
        send("У Вас в руках:")
        sendDescriptions(of: carrying, withGroundDescriptionsOnly: false, bigOnly: false)
    }
}
