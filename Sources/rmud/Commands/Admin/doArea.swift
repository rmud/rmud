import Foundation

extension Creature {
    func doArea(context: CommandContext) {
        guard !context.argument1.isEmpty else {
            send("""
                 Поддерживаемые команды:
                 область список
                 область создать <название> [стартовый внум] [последний внум]
                 область сохранить [название | все]
                 область идти [название]
                 """)
            return
        }

        if context.isSubCommand1(oneOf: ["список", "list"]) {
        } else if context.isSubCommand1(oneOf: ["создать", "create"]) {
        } else if context.isSubCommand1(oneOf: ["сохранить", "save"]) {
            saveArea(name: context.argument2)
        } else if context.isSubCommand1(oneOf: ["идти", "goto"]) {
            gotoArea(name: context.argument2)
        }
    }
    
    private func saveArea(name: String) {
        var areasToSave: [Area] = []
        if name.isEmpty {
            guard let area = inRoom?.area else {
                send("Комната, в который Вы находитесь, не принадлежит ни к одной из областей.")
                return
            }
            areasToSave = [area]
        } else {
            if let area = areaManager.areasByLowercasedName[name.lowercased()] {
                areasToSave = [area]
            } else if name.isEqualCI(toAny: ["все", "all"]) {
                guard !areaManager.areasByLowercasedName.isEmpty else {
                    send("Не найдено ни одной области.")
                    return
                }
                areasToSave = areaManager.areasByLowercasedName.sorted { pair1, pair2 in
                    pair1.key < pair2.key
                }.map{ $1 }
            } else {
                send("Области с таким названием не существует.")
                return
            }
        }
        
        for area in areasToSave {
            areaManager.save(area: area)
            send("Область сохранена: \(area.lowercasedName)")
        }
    }
    
    private func gotoArea(name: String) {
        if let area = areaManager.findArea(byAbbreviatedName: name) {
            guard let targetRoom = chooseTeleportTargetRoom(area: area) else {
                return
            }
            goto(room: targetRoom)
        } else {
            send("Области с таким названием не существует.")
        }
    }

    private func chooseTeleportTargetRoom(area: Area) -> Room? {
        if let originVnum = area.originVnum,
                let room = db.roomsByVnum[originVnum] {
            return room
        } else if let room = area.rooms.first {
            send("У области отсутствует основная комната, переход в первую комнату области.")
            return room
        } else {
            send("Область пуста.")
            return nil
        }
    }
}
