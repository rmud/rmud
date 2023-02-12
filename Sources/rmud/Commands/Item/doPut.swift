extension Creature {
    func doPut(context: CommandContext) {
        let items = context.items1
        guard !items.isEmpty, let whereTo = context.item2 else {
            send("Что Вы хотите положить и во что?")
            return
        }
        
        guard let container: ItemExtraData.Container = whereTo.extraData() else {
            act("@1и не является контейнером.", .to(self), .item(whereTo))
            return
        }
        
        guard !container.flags.contains(.closed) else {
            act("@1и закрыт@1(,а,о,ы).", .to(self), .item(whereTo))
            return
        }
        
        for item in items {
            if item !== whereTo {
                let containedWeight =
                    whereTo.weightWithContents() - whereTo.weight + item.weight
                guard containedWeight <= container.capacity else {
                    act("@1и в @2п не помест@1(и,и,и,я)тся.", .to(self), .item(item), .item(whereTo))
                    continue
                }
                act("Вы положили @1в в @2в.", .to(self), .item(item), .item(whereTo))
                act("1*и положил1(,а,о,и) @1в в @2в.", .toRoom, .excluding(self), .item(item), .item(whereTo))
                item.removeFromCreature()
                item.put(into: whereTo)
            } else {
                send("Предметы нельзя класть внутрь себя.")
            }
        }
    }
}
