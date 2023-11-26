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
            loadItem(vnum: vnum)
        } else if context.isSubCommand1(oneOf: ["монстра", "mobile"]) {
            guard !context.argument2.isEmpty else {
                send("Укажите номер монстра.")
                return
            }
            guard let vnum = Int(context.argument2) else {
                send("Некорректный номер монстра.")
                return
            }
            loadMobile(vnum: vnum)

        } else {
            send("Неизвестный тип объекта: \(context.argument1)")
        }
    }
    
    private func loadItem(vnum: Int) {
        guard let itemPrototype = db.itemPrototypesByVnum[vnum] else {
            send("Предмета с таким номером не существует.")
            return
        }
        let item = Item(prototype: itemPrototype, uid: nil, db: db /*, in: nil*/)
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
    }
    
    private func loadMobile(vnum: Int) {
        guard let mobilePrototype = db.mobilePrototypesByVnum[vnum] else {
            send("Монстра с таким номером не существует.")
            return
        }
        guard let room = inRoom else {
            send(messages.noRoom)
            return
        }
        let creature = Creature(prototype: mobilePrototype, uid: nil, db: db, room: room)
        logIntervention("\(nameNominative) создает \(creature.nameAccusative) в комнате \(room.vnum) \"\(room.name)\".")
        act("1*и сделал1(,а,о,и) волшебный жест, и появил2(ся,ась,ось,ись) 2и!",
            .toRoom, .excluding(self), .excluding(creature))
        act("Вы создали 2в.", .to(self), .excluding(creature))
        
        guard let area = room.area else {
            act("Не удалось определить область создания для 2р.",
                .to(self), .excluding(creature))
            return
        }
        if let mobile = creature.mobile {
            mobile.homeArea = area
            act("2д установлена область создания \"&1\"",
                .to(self), .excluding(creature), .text(area.description))
            if mobile.flags.contains(.returning) {
                mobile.homeRoom = room.vnum
                act("2и имеет свойство ВОЗВРАЩЕНИЕ. Назначена стартовая комната #1 (&1)",
                    .to(self), .excluding(creature), .number(room.vnum), .text(room.name))
            }
        }
    }
}
