import Foundation

extension Creature {
    private enum ShowMode {
        case areas
        case room
        case mobile
        case item
        case path
        case player
        case statistics
        case snoop
        case spells
        case overmax
        case linkdead
        case moons
        case multiplay
        case cases
        case materials
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
        ShowSubcommand("paths",     "путь",       "путь",       .admin, .path),
        ShowSubcommand("player",    "игрок",      "игрока",     .admin, .player ),
        ShowSubcommand("stats",     "статистика", "статистику", .admin, .statistics ),
        ShowSubcommand("snooping",  "шпионаж",    "шпионаж",    .admin, .snoop ),
        ShowSubcommand("spells",    "заклинание", "заклинание", .admin, .spells ),
        ShowSubcommand("overmax",   "превышение", "превышение", .admin, .overmax ),
        ShowSubcommand("linkdead",  "связь",      "связь",      .admin, .linkdead ),
        ShowSubcommand("moons",     "луны",       "луны",       .admin, .moons ),
        ShowSubcommand("multiplay", "мультиплей", "мультиплей", .admin, .multiplay ),
        ShowSubcommand("cases",     "падежи",     "падежи",     .admin, .cases),
        ShowSubcommand("materials", "материалы",  "материалы",  .admin, .materials)
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
            if let vnum = Int(value) {
                showMobile(vnum: vnum)
            } else {
                showCreature(named: value)
            }
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
        case .path:
            listPaths()
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
        case .materials:
            showMaterials()
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
                output += mode.rightExpandingTo(16)
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
    
    private func showMaterials() {
        let table = StringTable()
        table.add(row: .init(cells: [
            .init("название", nil, .right),
            .init("прочность", nil, .right),
            .init("магия", nil, .right),
            .init("огонь", nil, .right),
            .init("холод", nil, .right),
            .init("кислота", nil, .right),
            .init("электричество", nil, .right),
            .init("маг.удар", nil, .right),
            .init("удар", nil, .right),
        ]))
        for material in Material.allCases {
            let fragChance = material.fragChance
            
            table.add(row: .init(cells: [
                .init(material.name, Ansi.bYel, .right),
                .init(material.maxCondition, Ansi.bCyn, .right),
                .init(0, Ansi.bGrn, .right),
                .init(fragChance.heat, Ansi.bGrn, .right),
                .init(fragChance.cold, Ansi.bGrn, .right),
                .init(fragChance.acid, Ansi.bGrn, .right),
                .init(fragChance.electricity, Ansi.bGrn, .right),
                .init(fragChance.crush, Ansi.bGrn, .right),
                .init(fragChance.hit, Ansi.bRed, .right),
            ]))
        }
        send(table.description)
    }
    
    private func listAreas() {
        let areas = areaManager.areasByStartingVnum.sorted { $0.key < $1.key }
        for (_, area) in areas {
            let fromRoom = String(area.vnumRange.lowerBound).leftExpandingTo(5)
            let toRoom = String(area.vnumRange.upperBound).rightExpandingTo(5)
            let roomCount = String(area.rooms.count).rightExpandingTo(4)
            let areaName = area.lowercasedName.rightExpandingTo(30)
            let age = String(area.age).leftExpandingTo(2)
            let resetInterval = String(area.resetInterval).rightExpandingTo(2)
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
    
    private func showMobile(name: String) {
        
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
    
    private func listPaths() {
        guard let area = inRoom?.area else {
            send("Комната, в которой Вы находитесь, не принадлежит ни одной области.")
            return
        }
        for path in area.paths.sorted(by: { $0.0 < $1.0 }) {
            let vnums = path.value.sorted().map(String.init).joined(separator: ", ")
            send("\(bRed())\(path.key)\(nNrm()): \(cVnum())\(vnums)\(nNrm())")
        }
    }
}
