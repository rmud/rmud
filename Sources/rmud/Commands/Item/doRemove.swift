extension Creature {
    func doRemove(context: CommandContext) {
        guard !context.items1.isEmpty else {
            send("Что Вы хотите снять или убрать?")
            return
        }
      
        for item in context.items1 {
            guard let position = item.wornPosition else { continue }
            performRemove(position: position)
        }
    }
}
