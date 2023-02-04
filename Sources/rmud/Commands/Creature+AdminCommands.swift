import Foundation

// MARK: - doGoto

extension Creature {
    func doGoto(context: CommandContext) {
        guard let targetRoom = chooseTargetRoom(context: context) else {
            return
        }

        goto(room: targetRoom)
    }

    private func goto(room: Room) {
        sendPoofOut()
        teleportTo(room: room)
        sendPoofIn()
        lookAtRoom(ignoreBrief: false)
    }
    
    private func chooseTargetRoom(context: CommandContext) -> Room? {
        guard context.hasArguments else {
            send("Укажите номер комнаты, имя области, имя персонажа, название монстра или предмета.")
            return nil
        }
        
        if let creature = context.creature1 {
            return creature.inRoom
        } else if var item = context.item1 {
            while let container = item.inContainer {
                item = container
            }
            if let room = item.inRoom {
                return room
            } else if let wornBy = item.wornBy, canSee(wornBy), let inRoom = wornBy.inRoom {
                return inRoom
            } else if let carriedBy = item.carriedBy, canSee(carriedBy), let inRoom = carriedBy.inRoom {
                return inRoom
            }
        } else if let room = context.room1 {
            return room
        }
        return nil
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

// MARK: - doReload

extension Creature {
    func doReload(context: CommandContext) {
        
    }
}

// MARK: - doLoad

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
                item.put(in: room, activateDecayTimer: true)
                item.groundTimerTicsLeft = nil // disable ground timer
            }
        } else {
            send("Неизвестный тип объекта: \(context.argument1)")
        }
    }
}

// MARK: - doShow

extension Creature {
    private enum ShowMode {
        case areas
        case player
        case statistics
        case snoop
        case spells
        case overmax
        case linkdead
        case moons
        case multiplay
        case cases
        case room
        case mobile
        case item
    }
    
    private struct ShowSubcommand {
        let nameEnglish: String
        let nameNominative: String
        let nameAccusative: String
        let roles: Roles
        let mode: ShowMode
        
        init (_ nameEnglish: String, _ nameNominative: String, _ nameAccusative: String, _ roles: Roles, _ mode: ShowMode) {
            self.nameEnglish = nameEnglish
            self.nameNominative = nameNominative
            self.nameAccusative = nameAccusative
            self.roles = roles
            self.mode = mode
        }
    }
    
    private static var showSubcommands: [ShowSubcommand] = [
        // FIXME: сделать все в единственном числе? без аргумента показывать полный список
        ShowSubcommand("areas",     "область",    "область",    .admin, .areas ),
        ShowSubcommand("room",      "комната",    "комнату",    .admin, .room),
        ShowSubcommand("mobile",    "монстр",     "монстра",    .admin, .mobile),
        ShowSubcommand("item",      "предмет",    "предмет",    .admin, .item),
        ShowSubcommand("player",    "персонаж",   "персонажа",  .admin, .player ),
        ShowSubcommand("stats",     "статистика", "статистику", .admin, .statistics ),
        ShowSubcommand("snooping",  "шпионаж",    "шпионаж",    .admin, .snoop ),
        ShowSubcommand("spells",    "заклинание", "заклинание", .admin, .spells ),
        ShowSubcommand("overmax",   "превышение", "превышение", .admin, .overmax ),
        ShowSubcommand("linkdead",  "связь",      "связь",      .admin, .linkdead ),
        ShowSubcommand("moons",     "луны",       "луны",       .admin, .moons ),
        ShowSubcommand("multiplay", "мультиплей", "мультиплей", .admin, .multiplay ),
        ShowSubcommand("cases",     "падежи",     "падежи",     .admin, .cases)
    ]
    
    func doShow(context: CommandContext) {
        let modeString = context.argument1
        
        guard !modeString.isEmpty else {
            send("Режимы:")
            showModesHelp()
            return
        }
        
        guard let showMode = getShowMode(modeString) else {
            send("Неверный режим. Доступные режимы:")
            showModesHelp()
            return
        }
        
        let value = context.argument2
        
        switch showMode {
        case .areas:
            guard !value.isEmpty else {
                listAreas()
                return
            }
            showArea(name: areaName(fromArgument: value))
        case .player:
            break
        case .statistics:
            break
        case .snoop:
            break
        case .spells:
            break
        case .overmax:
            break
        case .linkdead:
            break
        case .moons:
            break
        case .multiplay:
            break
        case .cases:
            showCases()
        case .room:
            guard !value.isEmpty else {
                listRooms()
                return
            }
            guard let vnum = roomVnum(fromArgument: value) else {
                send("Некорректный номер комнаты.")
                return
            }
            showRoom(vnum: vnum)
        case .mobile:
            guard !value.isEmpty else {
                listMobiles()
                return
            }
            guard let vnum = Int(value) else {
                send("Некорректный номер существа.")
                return
            }
            showMobile(vnum: vnum)
        case .item:
            guard !value.isEmpty else {
                listItems()
                return
            }
            guard let vnum = Int(value) else {
                send("Некорректный номер предмета.")
                return
            }
            showItem(vnum: vnum)
        }
    }

    private func isSubcommandAccessible(_ subcommand: ShowSubcommand, roles: Roles) -> Bool {
        return subcommand.roles.isEmpty || !subcommand.roles.intersection(roles).isEmpty
    }
    
    private func showModesHelp() {
        var output = ""
        var modes: [String] = []
        for subcommand in Creature.showSubcommands {
            guard isSubcommandAccessible(subcommand, roles: player?.roles ?? []) else { continue }
            modes.append(subcommand.nameAccusative)
        }
        if !modes.isEmpty {
            for (index, mode) in modes.enumerated() {
                if index > 0 && index % 5 == 0 {
                    output += "\n"
                }
                output += mode.rightExpandingTo(minimumLength: 16)
            }
        } else {
            output += "Недоступно ни одного режима показа."
        }
        send(output)
    }
    
    private func getShowMode(_ modeString: String) -> ShowMode? {
        for subcommand in Creature.showSubcommands {
            guard !subcommand.roles.intersection(player?.roles ?? []).isEmpty else { continue }
            guard modeString.isAbbrevCI(ofAny: [subcommand.nameEnglish, subcommand.nameNominative, subcommand.nameAccusative]) else { continue }
            return subcommand.mode
        }
        return nil
    }
    
    private func showCases() {
        guard let area = inRoom?.area else {
            send("Комната, в которой Вы находитесь, не принадлежит ни одной области.")
            return
        }
        let table = StringTable()
        for (vnum, mobilePrototype) in area.prototype.mobilePrototypesByVnum.sorted(by: { $0.key < $1.key }) {
            let mp = mobilePrototype
            let isAnimate = !mp.flags.contains(.inanimate)
            let compressed = endings.compress(
                names: [mp.nameNominative, mp.nameGenitive, mp.nameDative, mp.nameAccusative, mp.nameInstrumental, mp.namePrepositional],
                isAnimate: isAnimate)

            //send("\(cVnum())\(vnum)\(nNrm()) \(isAnimate ? nGrn() : nYel())\(compressed)\(nNrm()) | \(mp.nameNominative) | \(mp.nameGenitive) | \(mp.nameDative) | \(mp.nameAccusative) | \(mp.nameInstrumental) | \(mp.namePrepositional)")
            table.add(row: [String(vnum), compressed, mp.nameGenitive, mp.nameDative, mp.nameAccusative, mp.nameInstrumental, mp.namePrepositional], colors: [cVnum(), isAnimate ? nGrn() : nYel()])
        }
        send(table.description)
    }
    
    private func listAreas() {
        let areas = areaManager.areasByStartingVnum.sorted { $0.key < $1.key }
        for (_, area) in areas {
            let fromRoom = String(area.vnumRange.lowerBound).leftExpandingTo(minimumLength: 5)
            let toRoom = String(area.vnumRange.upperBound).rightExpandingTo(minimumLength: 5)
            let roomCount = String(area.rooms.count).rightExpandingTo(minimumLength: 4)
            let areaName = area.lowercasedName.rightExpandingTo(minimumLength: 30)
            let age = String(area.age).leftExpandingTo(minimumLength: 2)
            let resetInterval = String(area.resetInterval).rightExpandingTo(minimumLength: 2)
            let resetCondition = area.resetCondition.nominative
            send("\(fromRoom)-\(toRoom) (:\(roomCount)) \(areaName) Возраст: \(age)/\(resetInterval)   Сброс: \(resetCondition)")
        }
    }
    
    private func showArea(name: String) {
        guard let area = areaManager.findArea(byAbbreviatedName: name) else {
            send("Области с названием \"\(name)\" не существует.")
            return
        }
        let areaPrototypeString = area.prototype.save(for: .ansiOutput(creature: self), with: db.definitions)
        send(areaPrototypeString.trimmingCharacters(in: .newlines))
    }
    
    private func listRooms() {
        guard let area = inRoom?.area else {
            send("Комната, в которой Вы находитесь, не принадлежит ни одной области.")
            return
        }
        for room in area.rooms.sorted(by: { $0.vnum < $1.vnum }) {
            send("\(cVnum())\(room.vnum)\(nNrm()) \(room.prototype.name)")
        }
    }
    
    private func showRoom(vnum: Int) {
        guard let room = db.roomsByVnum[vnum] else {
            send("Комнаты с виртуальным номером \(vnum) не существует.")
            return
        }
        let roomString = room.prototype.save(for: .ansiOutput(creature: self), with: db.definitions)
        send(roomString.trimmingCharacters(in: .newlines))
    }

    private func listMobiles() {
        guard let area = inRoom?.area else {
            send("Комната, в которой Вы находитесь, не принадлежит ни одной области.")
            return
        }
        for (vnum, mobilePrototype) in area.prototype.mobilePrototypesByVnum.sorted(by: { $0.key < $1.key }) {
            send("\(cVnum())\(vnum)\(nNrm()) \(mobilePrototype.nameNominative)")
        }
    }

    private func showMobile(vnum: Int) {
        guard let mobilePrototype = db.mobilePrototypesByVnum[vnum] else {
            send("Монстра с виртуальным номером \(vnum) не существует.")
            return
        }
        let mobileString = mobilePrototype.save(for: .ansiOutput(creature: self), with: db.definitions)
        send(mobileString.trimmingCharacters(in: .newlines))
    }
    
    private func listItems() {
        guard let area = inRoom?.area else {
            send("Комната, в которой Вы находитесь, не принадлежит ни одной области.")
            return
        }
        for (vnum, itemPrototype) in area.prototype.itemPrototypesByVnum.sorted(by: { $0.key < $1.key }) {
            send("\(cVnum())\(vnum)\(nNrm()) \(itemPrototype.nameNominative)")
        }
    }

    private func showItem(vnum: Int) {
        guard let itemPrototype = db.itemPrototypesByVnum[vnum] else {
            send("Предмета с виртуальным номером \(vnum) не существует.")
            return
        }
        let itemString = itemPrototype.save(for: .ansiOutput(creature: self), with: db.definitions)
        send(itemString.trimmingCharacters(in: .newlines))
    }
}

// MARK: - doSet

extension Creature {
    func doSet(context: CommandContext) {
        guard !context.argument1.isEmpty else {
            send("установить <области|комнате|монстру|предмету> <номер> [поле значение]")
            return
        }
        if context.isSubCommand1(oneOf: ["области", "область", "area"]) {
            guard let field = context.scanWord() else {
                send("Вы можете установить следующие поля области:")
                showAreaFields()
                return
            }
            let value = context.restOfString()
            guard !value.isEmpty else {
                send("Укажите значение.")
                return
            }
            setAreaPrototypeField(areaName: context.argument2, fieldName: field, value: value)
        } else if context.isSubCommand1(oneOf: ["комнате", "комната", "room"]) {
            guard let vnum = roomVnum(fromArgument: context.argument2) else {
                send("Некорректный номер комнаты.")
                return
            }
            guard let field = context.scanWord() else {
                send("Вы можете установить следующие поля комнаты:")
                showRoomFields()
                return
            }
            let value = context.restOfString()
            guard !value.isEmpty else {
                send("Укажите значение.")
                return
            }
            setRoomPrototypeField(vnum: vnum, fieldName: field, value: value)
        }
    }
    
   
    private func showAreaFields() {
        let text = format(fieldDefinitions: db.definitions.areaFields)
        send(text)
    }
    
    private func setAreaPrototypeField(areaName: String, fieldName: String, value: String) {
        //guard let area = areaManager.findArea(byAbbreviatedName: areaName) else {
        //    send("Область с таким названием не найдена.")
        //    return
        //}
        
        //let p = area.prototype
        
        
    }

    private func showRoomFields() {
        let text = format(fieldDefinitions: db.definitions.roomFields)
        send(text)
    }
    
    private func setRoomPrototypeField(vnum: Int, fieldName: String, value: String) {
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

    private func format(fieldDefinitions: FieldDefinitions) -> String {
        var result = ""
        
        for (index, fieldName) in fieldDefinitions.fieldsByLowercasedName.keys.sorted().enumerated() {
            if index != 0 {
                result += "\n"
            }
            result += fieldName.uppercased() //.rightExpandingTo(minimumLength: 20)
        }
        return result
    }
}

// MARK: - doArea

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
}

// MARK: - Utility methods

extension Creature {
    func areaName(fromArgument arg: String) -> String {
        return arg == "." ? (inRoom?.area?.lowercasedName ?? arg) : arg
    }
    
    func roomVnum(fromArgument arg: String) -> Int? {
        return arg == "." ? (inRoom?.vnum ?? nil) : Int(arg)
    }

    func sendPoofOut() {
        if let player = player,
                !player.poofout.isEmpty,
                let room = inRoom {
            for to in room.creatures {
                guard to != self && to.canSee(self) else { continue }
                to.send(player.poofout)
            }
        } else {
            act("1*и исчез1(,ла,ло,ли) в клубах дыма.", .toRoom, .excluding(self))
        }
    }
    
    func sendPoofIn() {
        if let player = player,
            !player.poofin.isEmpty,
            let room = inRoom {
            for to in room.creatures {
                guard to != self && to.canSee(self) else { continue }
                to.send(player.poofin)
            }
        } else {
            act("1*и появил1(ся,ась,ось,ись) в клубах дыма.", .toRoom, .excluding(self))
        }
    }
}
