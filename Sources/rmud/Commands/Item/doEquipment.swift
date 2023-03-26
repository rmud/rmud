import Foundation

extension Creature {
    func doEquipment(context: CommandContext) {
        typealias Slot = (EquipmentPosition, Item)
        
        let slots: [Slot] = EquipmentPosition.allCases.map { position -> Slot? in
            guard let item = equipment[position] else { return nil }
            return (position, item)
        }.compactMap({ $0 })

        guard !slots.isEmpty else {
            send("У Вас в экипировке ничего нет.")
            return
        }
        
        send("У Вас в экипировке:")
        for (position, item) in slots {
            let whereAt = "<\(position.bodypartInfo.name)>".rightExpandingTo(15)
            act("&1 @1и", .to(self), .text(whereAt), .item(item))
        }
    }
}
