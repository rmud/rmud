import Foundation

extension Creature {
    func showItem(named name: String) {
        guard !name.isEmpty else {
            send("Укажите название предмета.")
            return
        }
        
        var creatures: [Creature] = []
        var items: [Item] = []
        var room: Room?
        var string = ""
        
        let scanner = Scanner(string: name)
        guard fetchArgument(
            from: scanner,
            what: .item,
            where: .world,
            cases: .accusative,
            condition: nil,
            intoCreatures: &creatures,
            intoItems: &items,
            intoRoom: &room,
            intoString: &string
        ) else {
            send("Предмета с таким названием не существует.")
            return
        }

        if let item = items.first {
            showStats(of: item)
        }
    }

    private func showStats(of item: Item) {
        sendStatGroup([
            .init("предмет", item.vnum),
            .init("уид", item.uid)
        ], indent: 0)
        
        
        sendStatGroup([
            .init("название", item.nameCompressed()),
            .init("синонимы", item.synonyms.joined(separator: " "))
        ])
        
        sendStat(.init("род", .enumeration(Int64(item.gender.rawValue))))
   
        do {
            let itemTypes: Set<Int64> = Set(item.extraDataByItemType.keys.map { itemType in
                Int64(itemType.rawValue)
            })
            var stats: [StatInfo] = [
                .init("тип", .list(itemTypes))
            ]
            if !item.wearFlags.isEmpty {
                stats.append(.init("использование", .flags(Int64(item.wearFlags.rawValue))))
            }
            sendStatGroup(stats)
        }
        
        sendStat(.init("строка", item.groundDescription))
        sendStat(.init("описание", .longText(item.description)))
        sendStat(.init("знание", .longText(item.legend)))
        
        for extraDescription in item.extraDescriptions {
            sendStat(.init("дополнительно", extraDescription.keyword))
            sendStat(.init("текст", .longText(extraDescription.description)))
        }
        
        do {
            let (restrictFlags: restrict, allowFlags: allow) =
            ItemAccessFlags.split(restrictFlags: item.restrictFlags)
            var stats: [StatInfo] = []
            if !restrict.isEmpty {
                stats.append(.init("запрет", .flags(Int64(restrict.rawValue))))
            }
            if !allow.isEmpty {
                stats.append(.init("разрешение", .flags(Int64(allow.rawValue))))
            }
            if !stats.isEmpty {
                sendStatGroup(stats)
            }
        }
        
        if !item.extraFlags.isEmpty {
            sendStat(.init("псвойства", .flags(Int64(item.extraFlags.rawValue))))
        }
        if !item.stateFlags.isEmpty {
            sendStat(.init("псостояния", .flags(Int64(item.stateFlags.rawValue))))
        }

        if !item.affects.isEmpty {
            let affectTypes: Set<Int64> = Set(item.affects.map { affectType in
                Int64(affectType.rawValue)
            })
            sendStat(.init("пэффекты", .list(affectTypes)))
        }
        
        do {
            var stats: [StatInfo] = []
            if item.weight != nil || item.weightWithContents() > 0 {
                let weight = item.weight ?? 0
                stats.append(.init("вес", weight,
                                   modifier: item.weightWithContents() - weight))
            }
            stats.append(.init("цена", item.cost))
            if let decayTimerTicsLeft = item.decayTimerTicsLeft {
                stats.append(.init("жизньвкл", item.isDecayTimerEnabled ? "да" : "нет"))
                stats.append(.init("жизнь", decayTimerTicsLeft))
            }
            if let groundTimerTicsLeft = item.groundTimerTicsLeft {
                stats.append(.init("земля", groundTimerTicsLeft))
            }
            sendStatGroup(stats)
        }
        
        do {
            var stats: [StatInfo] = []
            // TODO: show owner for private items
            if let container = item.inContainer {
                stats.append(.init("внутри", container.nameCompressed()))
            }
            if let carriedBy = item.carriedBy {
                stats.append(.init("инвентарь", carriedBy.nameCompressed()))
            }
            if let wornBy = item.wornBy {
                stats.append(.init("надет", wornBy.nameCompressed()))
            }
            if let nearestRoom = item.findNearestRoom() {
                stats.append(.init("комната", "[\(nearestRoom.vnum)] \(nearestRoom.name)"))
            }
            sendStatGroup(stats)
        }
        
        do {
            var stats: [StatInfo] = [
                .init("материал", .enumeration(Int64(item.material.rawValue))),
                .init("качество", item.qualityPercentage)
            ]
            stats.append(.init("состояние", item.condition, maxValue: item.maxCondition))
            if let repairComplexity = item.prototype.repairComplexity {
                stats.append(.init("починка", Int64(repairComplexity)))
            }
            //stats.append(.init("заклятие", item.enchant_lev))
            sendStatGroup(stats)
        }
        
        do {
            var stats: [StatInfo] = []
            if let loadChangePercentage = item.prototype.loadChancePercentage {
                stats.append(.init("шанс", loadChangePercentage))
            }
            let countInWorld = db.itemsCountByVnum[item.vnum] ?? 0
            stats.append(.init("создано", countInWorld))
            if let loadMaximum = item.prototype.maximumCountInWorld {
                stats.append(.init("предел", loadMaximum))
            }
            sendStatGroup(stats)
        }
        
        if let light = item.asLight() {
            sendStatGroup([
                .init("свет.время", light.ticsLeft)
            ])
        }
        if let scroll = item.asScroll() {
            sendStatGroup([
                .init("свиток.заклинания", spellsAndLevels(scroll.spellsAndLevels))
            ])
        }
        if let potion = item.asPotion() {
            sendStatGroup([
                .init("зелье.заклинания", spellsAndLevels(potion.spellsAndLevels))
            ])
        }
        if let wand = item.asWand() {
            sendStatGroup([
                .init("палочка.осталось", wand.chargesLeft),
                .init("палочка.заряды", wand.maximumCharges),
                .init("палочка.заклинания", spellsAndLevels(wand.spellsAndLevels))
            ])
        }
        if let staff = item.asStaff() {
            sendStatGroup([
                .init("посох.осталось", staff.chargesLeft),
                .init("посох.заряды", staff.maximumCharges),
                .init("посох.заклинания", spellsAndLevels(staff.spellsAndLevels))
            ])
        }
        if let weapon = item.asWeapon() {
            let damage: Dice<Int64> = weapon.damage.int64Dice ?? Dice()
            let min = damage.minimum()
            let avg = damage.average()
            let max = damage.maximum()
            sendStatGroup([
                .init("оружие.вред", .dice(damage)),
                .init("оружие.тип", .enumeration(Int64(weapon.weaponType.rawValue))),
                .init("оружие.яд", Int64(weapon.poisonLevel)),
                .init("оружие.волшебство", Int64(weapon.magicalityLevel))
            ], terminator: "")
            send(" \(bGra()); вред: \(min) / \(String(format: "%.1f", avg)) / \(max)\(nNrm())")
        }
        if let armor = item.asArmor() {
            sendStatGroup([
                .init("доспех.прочность", armor.armorClass)
            ])
        }
        if let container = item.asContainer() {
            var stats: [StatInfo] = [
                .init("контейнер.вместимость", container.capacity),
            ]
            if !container.flags.isEmpty {
                stats.append(.init("контейнер.свойства", .flags(Int64(container.flags.rawValue))))
            }
            stats.append(.init("контейнер.ключ", container.keyVnum))
            if container.flags.contains(.corpse) {
                if let mobileVnum = container.mobileVnum {
                    stats.append(.init("контейнер.монстр", mobileVnum))
                }
                stats.append(.init("контейнер.яд", container.poisonLevel))
                if let corpseSize = container.corpseSize {
                    stats.append(.init("контейнер.труп_размер", corpseSize))
                }
            }
            sendStatGroup(stats)
            sendStatGroup([
                .init("контейнер.замок_сложность", container.lockDifficulty),
                .init("контейнер.замок_состояние", .enumeration(Int64(container.lockCondition.rawValue))),
                .init("контейнер.замок_повреждение", container.lockDamage)
            ])
        }
        if let vessel = item.asVessel() {
            sendStatGroup([
                .init("сосуд.осталось", vessel.usedCapacity),
                .init("сосуд.емкость", vessel.totalCapacity),
                .init("сосуд.жидкость", .enumeration(Int64(vessel.liquid.rawValue))),
                .init("сосуд.яд", vessel.poisonLevel)
            ])
        }
        if let fountain = item.asFountain() {
            sendStatGroup([
                .init("фонтан.осталось", fountain.usedCapacity),
                .init("фонтан.емкость", fountain.totalCapacity),
                .init("фонтан.жидкость", .enumeration(Int64(fountain.liquid.rawValue))),
                .init("фонтан.яд", fountain.poisonLevel)
            ])
        }
        if let note = item.asNote() {
            sendStat(.init("записка.текст", .longText(note.text)))
        }
        if let food = item.asFood() {
            sendStatGroup([
                .init("пища.насыщение", food.satiation),
                .init("пища.влажность", food.moisture),
                .init("пища.яд", food.poisonLevel)
            ])
        }
        if let money = item.asMoney() {
            sendStat(.init("деньги.сумма", money.amount))
        }
        if let spellbook = item.asSpellbook() {
            let spellsAndChances: [(Int64, Int64?)] = spellbook.spellsAndChances.map { (spell, chance) in
                (Int64(spell.rawValue), Int64(chance))
            }
            sendStat(.init("книга.заклинания", .dictionary(Dictionary(uniqueKeysWithValues: spellsAndChances))))
        }
        if let board = item.asBoard() {
            sendStatGroup([
                .init("доска.номер", board.boardTypeIndex),
                .init("доска.чтение", board.readLevel),
                .init("доска.запись", board.writeLevel)
            ])
        }
        if let receipt = item.asReceipt() {
            var stats: [StatInfo] = [
                .init("расписка.скакун", receipt.mountVnum)
            ]
            let stablemanVnums: Set<Int64> = Set(receipt.stablemanVnums.map { vnum in
                Int64(vnum)
            })
            if !stablemanVnums.isEmpty {
                stats.append(.init("расписка.конюхи", .list(stablemanVnums)))
            }
            if let stableRoomVnum = receipt.stableRoomVnum {
                stats.append(.init("расписка.конюшня", stableRoomVnum))
            }
            sendStatGroup(stats)
        }

        if !item.contains.isEmpty {
            let contents: [String] = item.contains.map { item in
                "[\(item.vnum)] \(item.nameCompressed())"
            }
            sendStat(.init("содержимое", .longText(contents)))
        }
        
        // TODO: scripts
    }
    
    private func spellsAndLevels(_ spellsAndLevels: [Spell: UInt8]) -> Value {
        let spellsAndLevels: [(Int64, Int64?)] = spellsAndLevels.map { (spell, level) in
            (Int64(spell.rawValue), Int64(level))
        }
        return .dictionary(Dictionary(uniqueKeysWithValues: spellsAndLevels))
    }
}
