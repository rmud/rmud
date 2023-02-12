extension Creature {
    func doGet(context: CommandContext) {
        guard context.hasArguments else {
            send("Что Вы хотите взять?")
            return
        }

        if context.items2.isEmpty {
            performGetFromRoom(itemNames: context.argument1)
        } else {
            let containers = context.items2
            performGet(itemNames: context.argument1, from: containers)
        }
    }
    
    private func performGet(itemNames: String, from containers: [Item]) {
        for container in containers {
            guard canSee(container) else { continue }
            guard container.hasType(.container) else {
                act("@1и не является контейнером.", .to(self), .item(container))
                continue
            }
            //get_from_container(ch, cont, parg1);
        }
    }
    
    private func performGetFromRoom(itemNames: String) {
        var context = FetchArgumentContext(word: itemNames, isCountable: true, isMany: true)
        var items: [Item] = []
        if let room = inRoom {
            let _ = fetchItems(context: &context, from: room.items, into: &items, cases: .accusative)
        }
        guard !items.isEmpty else {
            send("Здесь нет такого предмета.")
            return
        }
        for item in items {
            guard canTake(item: item, isSilent: false) else { continue }
            act("Вы взяли @1в.", .to(self), .item(item))
            act("1*и взял1(,а,о,и) @1в.", .toRoom, .excluding(self), .item(item))
            item.removeFromRoom()
            item.give(to: self)
        }
    }
}
