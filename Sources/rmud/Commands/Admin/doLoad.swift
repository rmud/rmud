import Foundation

extension Creature {
    func doLoad(context: CommandContext) {
        guard context.hasArguments else {
            send("создать <предмет|монстра> <номер>")
            return
        }
        if context.isSubCommand1(oneOf: ["предмет", "item"]) {
            guard !context.argument2.isEmpty else {
                send("Укажите номер предмета.")
                return
            }
            guard let vnum = Int(context.argument2) else {
                send("Некорректный номер предмета.")
                return
            }
            guard let itemPrototype = db.itemPrototypesByVnum[vnum] else {
                send("Предмета с таким номером не существует.")
                return
            }
            let item = Item(prototype: itemPrototype, uid: db.createUid() /*, in: nil*/)
            act("1*и сделал1(,а,о,и) волшебный жест, и появил@1(ся,ась,ось,ись) @1и!", .toRoom, .excluding(self), .item(item))
            act("Вы создали @1в.", .to(self), .item(item))
            
            var isOvermax = false
            let countInWorld = db.itemsCountByVnum[vnum] ?? 0
            if let loadMaximum = itemPrototype.maximumCountInWorld,
                    countInWorld >= loadMaximum {
                act("ВНИМАНИЕ! Превышен максимум экземпляров для @1р!", .to(self), .item(item))
                isOvermax = true
            }
            logIntervention("\(nameNominative) создает\(isOvermax ? ", ПРЕВЫСИВ ПРЕДЕЛ,":"") \(item.nameAccusative) в комнате \"\(inRoom?.name ?? "без имени")\".")
            if item.wearFlags.contains(.take) {
                item.give(to: self)
            } else {
                guard let room = inRoom else {
                    item.extract(mode: .purgeAllContents)
                    send(messages.noRoom)
                    return
                }
                item.put(
                    in: room,
                    activateDecayTimer: true,
                    activateGroundTimer: false
                )
            }
        } else {
            send("Неизвестный тип объекта: \(context.argument1)")
        }
    }
}
