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
        let table = StringTable()
        for (position, item) in slots {
            let whereAt = "<\(position.bodypartInfo.name)>"
            let itemName = item.nameNominative.full
            let conditionPercentage = item.conditionPercentage()
            let condition = ItemCondition(
                conditionPercentage: conditionPercentage
            ).shortDescription
            let conditionColor = percentageColor(conditionPercentage)
            table.add(row: [whereAt, itemName, condition],
                      colors: [bGra(), nNrm(), conditionColor])
        }
        send(table.description)
    }
}
