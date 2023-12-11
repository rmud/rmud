import Foundation

extension Creature {
    func setAreaPrototypeField(areaName: String, fieldName: String, value: String) {
        //guard let area = areaManager.findArea(byAbbreviatedName: areaName) else {
        //    send("Область с таким названием не найдена.")
        //    return
        //}
        
        //let p = area.prototype
        
        
    }

    func setRoomPrototypeField(vnum: Int, fieldName: String, value: String) {
        guard let room = db.roomsByVnum[vnum] else {
            send("Комнаты с виртуальным номером \(vnum) не существует.")
            return
        }
        guard let fieldInfo = db.definitions.roomFields.fieldInfo(byAbbreviatedFieldName: fieldName) else {
            send("Поля комнаты с таким названием не существует.")
            return
        }

        let p = room.prototype
        
        switch fieldInfo.lowercasedName {
        // комната
        case "название": p.name = adjusted(p.name, with: value, constrainedTo: fieldInfo)
        case "комментарий": p.comment = adjusted(p.comment, with: value, constrainedTo: fieldInfo)
        case "местность": p.terrain = adjusted(p.terrain, with: value, constrainedTo: fieldInfo)
        case "описание": p.description = adjusted(p.description, with: value, constrainedTo: fieldInfo)
        // дополнительно.ключ
        // дополнительно.текст
        // проход.направление
        // проход.комната
        // проход.тип
        // проход.признаки
        // проход.замок_ключ
        // проход.замок_сложность
        // проход.замок_состояние
        // проход.замок_повреждение
        // проход.расстояние
        case "юг.описание":
            let exit = p.exits[.south] ?? RoomPrototype.ExitPrototype()
            exit.description = adjusted(exit.description, with: value, constrainedTo: fieldInfo)
            p.exits[.south] = exit
        // проход.описание
        // ксвойства
        // легенда.название
        // легенда.символ
        // монстры
        // предметы
        case "деньги":   p.coinsToLoad = adjusted(p.coinsToLoad, with: value, constrainedTo: fieldInfo)
        // кперехват.событие
        // кперехват.выполнение
        // кперехват.игроку
        // кперехват.жертве
        // кперехват.комнате
        default: send("Это поле не может быть установлено.")
        }
    }
    
    func setMobilePrototypeField(vnum: Int, fieldName: String, value: String) {
        guard let mobile = db.mobilePrototypesByVnum[vnum] else {
            send("Монстра с виртуальным номером \(vnum) не существует.")
            return
        }
        guard let fieldInfo = db.definitions.mobileFields.fieldInfo(byAbbreviatedFieldName: fieldName) else {
            send("Поля монстра с таким названием не существует.")
            return
        }

        //let p = mobile.prototype
        
        switch fieldInfo.lowercasedName {
        default: send("Это поле не может быть установлено.")
        }
    }

    private func adjusted(_ initial: String, with arg: String, constrainedTo fieldInfo: FieldInfo) -> String {
        switch fieldInfo.type {
        case .line:
            return arg
        default:
            send("Поле с этим типом невозможно установить.")
        }
        return initial
    }

    private func adjusted(_ initial: [String], with arg: String, constrainedTo fieldInfo: FieldInfo) -> [String] {
        switch fieldInfo.type {
        case .longText:
            if arg.starts(with: "+") {
                return initial + [String(arg.droppingPrefix())]
            }
            return arg.wrapping(totalWidth: 70).components(separatedBy: .newlines)
        default:
            send("Поле с этим типом невозможно установить.")
        }
        return initial
    }

    private func adjusted<T: FixedWidthInteger>(_ initial: T, with arg: String, constrainedTo fieldInfo: FieldInfo) -> T {
        switch fieldInfo.type {
        case .number:
            return T(arg) ?? initial
        default:
            send("Поле с этим типом невозможно установить.")
        }
        return initial
    }
    
    private func adjusted<T: RawRepresentable>(_ initial: T, with arg: String, constrainedTo fieldInfo: FieldInfo) -> T where T.RawValue: FixedWidthInteger {
        switch fieldInfo.type {
        case .enumeration:
            let enumSpec = db.definitions.enumerations.enumSpecsByAlias[fieldInfo.lowercasedName]
            guard let number = enumSpec?.value(byAbbreviatedName: arg) else {
                send("Неизвестный элемент перечисления: \"\(arg)\"")
                return initial
            }
            let rawValue = T.RawValue(exactly: number) ?? initial.rawValue
            return T.init(rawValue: rawValue) ?? initial
        default:
            send("Поле с этим типом невозможно установить.")
        }
        return initial
    }
}
