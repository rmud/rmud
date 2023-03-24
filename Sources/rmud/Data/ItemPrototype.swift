import Foundation

class ItemPrototype {
    var vnum: Int // Required
    var extraFlags: ItemExtraFlags = [] // Optional
    var nameNominative: String // Required
    var nameGenitive: String
    var nameDative: String
    var nameAccusative: String
    var nameInstrumental: String
    var namePrepositional: String
    var comment: [String] // Optional
    var synonyms: String // Optional
    var groundDescription: String // Optional
    var description: [String] = [] // Optional
    var extraDescriptions: [ExtraDescription] = [] // Optional
    var gender: Gender? // Optional
    var material: Material // Required
    var weight: Int // Required

    // The rest are optional
    var extraDataByItemType: [ItemType: ItemExtraDataType] = [:]
    var applies: [Apply: Int8] = [:]
    var coinsToLoad: Int?
    var decayTimerTics: Int?
    var restrictFlags: ItemAccessFlags = []
    var legend: [String] = []
    var wearPercentage: UInt8?
    var wearFlags: ItemWearFlags = []
    var qualityPercentage: UInt16? // can go over 100
    var eventOverrides: [Event<ItemEventId>] = []
    var repairCompexity: UInt8?
    var maximumCountInWorld: Int?
    var procedures: Set<Int> = []
    var affects: Set<AffectType> = []
    var contentsToLoadCountByVnum: [Int: Int] = [:]
    var cost: Int?
    var loadChancePercentage: UInt8?
    
    init?(entity: Entity) {
        // MARK: Key fields
        
        // Required:
        guard let vnum = entity["предмет"]?.int else {
            assertionFailure()
            return nil
        }
        
        self.vnum = vnum
        // We need to parse extraFlags this early because of 'animate' flag
        extraFlags = ItemExtraFlags(rawValue: entity["псвойства"]?.uint32 ?? 0)
        var name = entity["название"]?.string ?? "Без названия"
        if name.contains("[") {
            extraFlags.insert(.animate)
            name = name
                .replacingOccurrences(of: "[", with: "(")
                .replacingOccurrences(of: "]", with: ")")
        }
        let names = endings.decompress(names: name,
                                       isAnimate: extraFlags.contains(.animate))
        nameNominative = names[0]
        nameGenitive = names[1]
        nameDative = names[2]
        nameAccusative = names[3]
        nameInstrumental = names[4]
        namePrepositional = names[5]
        comment = entity["комментарий"]?.stringArray ?? []
        synonyms = entity["синонимы"]?.string ?? ""
        groundDescription = entity["строка"]?.string ?? ""
        description = entity["описание"]?.stringArray ?? []
        for i in entity.structureIndexes("дополнительно") {
            guard let key = entity["дополнительно.ключ", i]?.string else {
                assertionFailure()
                continue
            }
            let description = ExtraDescription()
            description.keyword = key
            description.description = entity["дополнительно.текст", i]?.stringArray ?? []
            extraDescriptions.append(description)
        }
        if let gender = entity["род"]?.uint8 {
            self.gender = Gender(rawValue: gender)
        }
        material = Material(rawValue: entity["материал"]?.uint8 ?? 0) ?? .noMaterial
        weight = entity["вес"]?.int ?? 0

        // MARK: Item types
        
        if let itemTypes = entity["тип"]?.list {
            for value in itemTypes {
                guard let itemTypeRaw = UInt8(exactly: value) else {
                    logError("Item \(vnum): 'тип': invalid item type: \(value)")
                    continue
                }
                switch ItemType(rawValue: itemTypeRaw) ?? .none {
                case .none:      break
                case .light:     let _: ItemExtraData.Light     = findOrCreateExtraData()
                case .scroll:    let _: ItemExtraData.Scroll    = findOrCreateExtraData()
                case .wand:      let _: ItemExtraData.Wand      = findOrCreateExtraData()
                case .staff:     let _: ItemExtraData.Staff     = findOrCreateExtraData()
                case .weapon:    let _: ItemExtraData.Weapon    = findOrCreateExtraData()
                case .treasure:  let _: ItemExtraData.Treasure  = findOrCreateExtraData()
                case .armor:     let _: ItemExtraData.Armor     = findOrCreateExtraData()
                case .potion:    let _: ItemExtraData.Potion    = findOrCreateExtraData()
                case .worn:      let _: ItemExtraData.Worn      = findOrCreateExtraData()
                case .other:     let _: ItemExtraData.Other     = findOrCreateExtraData()
                case .container: let _: ItemExtraData.Container = findOrCreateExtraData()
                case .note:      let _: ItemExtraData.Note      = findOrCreateExtraData()
                case .vessel:    let _: ItemExtraData.Vessel    = findOrCreateExtraData()
                case .key:       let _: ItemExtraData.Key       = findOrCreateExtraData()
                case .food:      let _: ItemExtraData.Food      = findOrCreateExtraData()
                case .money:     let _: ItemExtraData.Money     = findOrCreateExtraData()
                case .pen:       let _: ItemExtraData.Pen       = findOrCreateExtraData()
                case .boat:      let _: ItemExtraData.Boat      = findOrCreateExtraData()
                case .fountain:  let _: ItemExtraData.Fountain  = findOrCreateExtraData()
                case .spellbook: let _: ItemExtraData.Spellbook = findOrCreateExtraData()
                case .board:     let _: ItemExtraData.Board     = findOrCreateExtraData()
                case .receipt:   let _: ItemExtraData.Receipt   = findOrCreateExtraData()
                case .token:     let _: ItemExtraData.Token     = findOrCreateExtraData()
                }
            }
        }
        
        // MARK: Item types: deprecated fields
        var spellsLevel: UInt8?
        if let ticsLeft = entity["свет"]?.int {
            if let light: ItemExtraData.Light = extraData() {
                light.ticsLeft = ticsLeft
            }
        }
        if let level = entity["уровень"]?.uint8 {
            spellsLevel = level
        }
        for name in ["закл1", "закл2", "закл3", "заклинание"] {
            if let spellRaw = entity[name]?.uint16 {
                guard let spell = Spell(rawValue: spellRaw) else {
                    logError("Item \(vnum): '\(name)': invalid spell name")
                    continue
                }
                if let scroll: ItemExtraData.Scroll = extraData() {
                    scroll.spellsAndLevels[spell] = spellsLevel ?? 12
                }
                if let wand: ItemExtraData.Wand = extraData() {
                    wand.spellsAndLevels[spell] = spellsLevel ?? 12
                }
                if let staff: ItemExtraData.Staff = extraData() {
                    staff.spellsAndLevels[spell] = spellsLevel ?? 16
                }
                if let spellbook: ItemExtraData.Spellbook = extraData() {
                    spellbook.spellsAndChances[spell] = 1
                }
            }
        }
        if let maximumCharges = entity["заряды"]?.uint8 {
            if let wand: ItemExtraData.Wand = extraData() {
                wand.maximumCharges = maximumCharges
                wand.chargesLeft = maximumCharges
            }
            if let staff: ItemExtraData.Staff = extraData() {
                staff.maximumCharges = maximumCharges
                staff.chargesLeft = maximumCharges
            }
        }
        if let damage = entity["вред"]?.dice?.intDice {
            if let weapon: ItemExtraData.Weapon = extraData() {
                weapon.damage = damage
            }
        }
        if let weaponType = entity["удар"]?.uint16 {
            if let weapon: ItemExtraData.Weapon = extraData() {
                weapon.weaponType = WeaponType(rawValue: weaponType) ?? .bareHand
            }
        }
        if let poisonLevel = entity["яд"]?.uint8 {
            if let weapon: ItemExtraData.Weapon = extraData() {
                weapon.poisonLevel = poisonLevel
            }
            if let container: ItemExtraData.Container = extraData() {
                container.poisonLevel = poisonLevel
            }
            if let vessel: ItemExtraData.Vessel = extraData() {
                vessel.poisonLevel = poisonLevel
            }
            if let food: ItemExtraData.Food = extraData() {
                food.poisonLevel = poisonLevel
            }
            if let fountain: ItemExtraData.Fountain = extraData() {
                fountain.poisonLevel = poisonLevel
            }
        }
        if let magicalityLevel = entity["волшебство"]?.uint8 {
            if let weapon: ItemExtraData.Weapon = extraData() {
                weapon.magicalityLevel = magicalityLevel
            }
        }
        if let armorClass = entity["прочность"]?.int {
            if let armor: ItemExtraData.Armor = extraData() {
                armor.armorClass = armorClass
            }
        }
        if let capacity = entity["вместимость"]?.int {
            if let container: ItemExtraData.Container = extraData() {
                container.capacity = capacity
            }
        }
        if let flags = entity["косвойства"]?.uint8 {
            if let container: ItemExtraData.Container = extraData() {
                container.flags = ContainerFlags(rawValue: flags)
            }
        }
        if let keyVnum = entity["ключ"]?.int {
            if let container: ItemExtraData.Container = extraData() {
                container.keyVnum = keyVnum
            }
        }
        if let lockDifficulty = entity["косложность"]?.uint8 {
            if let container: ItemExtraData.Container = extraData() {
                container.lockDifficulty = lockDifficulty
            }
        }
        if let text = entity["текст"]?.stringArray {
            if let note: ItemExtraData.Note = extraData() {
                note.text = text
            }
        }
        if let totalCapacity = entity["емкость"]?.uint8 {
            if let vessel: ItemExtraData.Vessel = extraData() {
                vessel.totalCapacity = totalCapacity
                vessel.usedCapacity = totalCapacity
            }
            if let fountain: ItemExtraData.Fountain = extraData() {
                fountain.totalCapacity = totalCapacity
                fountain.usedCapacity = totalCapacity
            }
        }
        if let liquidRaw = entity["жидкость"]?.uint8,
                let liquid = Liquid(rawValue: liquidRaw) {
            if let vessel: ItemExtraData.Vessel = extraData() {
                vessel.liquid = liquid
            }
            if let fountain: ItemExtraData.Fountain = extraData() {
                fountain.liquid = liquid
            }
        }
        if let satiation = entity["насыщение"]?.uint8 {
            if let food: ItemExtraData.Food = extraData() {
                food.satiation = satiation
            }
        }
        if let moisture = entity["влажность"]?.uint8 {
            if let food: ItemExtraData.Food = extraData() {
                food.moisture = moisture
            }
        }
        if let amount = entity["сумма"]?.int {
            if let money: ItemExtraData.Money = extraData() {
                money.amount = amount
            }
        }
        if let boardTypeIndex = entity["номер"]?.int {
            if let board: ItemExtraData.Board = extraData() {
                board.boardTypeIndex = boardTypeIndex
            }
        }
        if let boardTypeIndex = entity["знач0"]?.int {
            if let board: ItemExtraData.Board = extraData() {
                board.boardTypeIndex = boardTypeIndex
            }
        }
        if let readLevel = entity["чтение"]?.uint8 {
            if let board: ItemExtraData.Board = extraData() {
                board.readLevel = readLevel
            }
        }
        if let readLevel = entity["знач1"]?.uint8 {
            if let board: ItemExtraData.Board = extraData() {
                board.readLevel = readLevel
            }
        }
        if let writeLevel = entity["запись"]?.uint8 {
            if let board: ItemExtraData.Board = extraData() {
                board.writeLevel = writeLevel
            }
        }
        if let writeLevel = entity["знач2"]?.uint8 {
            if let board: ItemExtraData.Board = extraData() {
                board.writeLevel = writeLevel
            }
        }
        if let mountVnum = entity["скакун"]?.int {
            if let receipt: ItemExtraData.Receipt = extraData() {
                receipt.mountVnum = mountVnum
            }
        }
        if let receipt: ItemExtraData.Receipt = extraData() {
            for name in ["конюх1", "конюх2", "конюх3"] {
                if let stablemanVnum = entity[name]?.int {
                    receipt.stablemanVnums.insert(stablemanVnum)
                }
            }
        }
        if let stableRoomVnum = entity["конюшня"]?.int {
            if let receipt: ItemExtraData.Receipt = extraData() {
                receipt.stableRoomVnum = stableRoomVnum
            }
        }
        
        // MARK: Item types: new style fields will overwrite deprecated ones
        for i in entity.structureIndexes("свет") {
            if let ticsLeft = entity["свет.время", i]?.int {
                (findOrCreateExtraData() as ItemExtraData.Light).ticsLeft = ticsLeft
            }
        }
        for i in entity.structureIndexes("свиток") {
            if let spellsAndLevels = entity["свиток.заклинания", i]?.dictionary {
                let extraData: ItemExtraData.Scroll = findOrCreateExtraData()
                for (key, value) in spellsAndLevels {
                    guard let spellRaw = UInt16(exactly: key), let levelRaw = value,
                        let level = UInt8(exactly: levelRaw), let spell = Spell(rawValue: spellRaw)
                        else {
                            logError("Item \(vnum): 'свиток.заклинания': invalid spell or spell level: \(key)=\(value.unwrapOptional)")
                            continue
                    }
                    extraData.spellsAndLevels[spell] = level
                }
            }
        }
        for i in entity.structureIndexes("палочка") {
            if let spellsAndLevels = entity["палочка.заклинания", i]?.dictionary {
                let extraData: ItemExtraData.Wand = findOrCreateExtraData()
                for (key, value) in spellsAndLevels {
                    guard let spellRaw = UInt16(exactly: key), let levelRaw = value,
                        let level = UInt8(exactly: levelRaw), let spell = Spell(rawValue: spellRaw)
                        else {
                            logError("Item \(vnum): 'палочка.заклинания': invalid spell or spell level: \(key)=\(value.unwrapOptional)")
                            continue
                    }
                    extraData.spellsAndLevels[spell] = level
                }
            }
            if let maximumCharges = entity["палочка.заряды", i]?.uint8 {
                let extraData: ItemExtraData.Wand = findOrCreateExtraData()
                extraData.chargesLeft = maximumCharges
                extraData.maximumCharges = maximumCharges
            }
            if let chargesLeft = entity["палочка.осталось", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Wand).chargesLeft = chargesLeft
            }
        }
        for i in entity.structureIndexes("посох") {
            if let spellsAndLevels = entity["посох.заклинания", i]?.dictionary {
                let extraData: ItemExtraData.Wand = findOrCreateExtraData()
                for (key, value) in spellsAndLevels {
                    guard let spellRaw = UInt16(exactly: key), let levelRaw = value,
                        let level = UInt8(exactly: levelRaw), let spell = Spell(rawValue: spellRaw)
                        else {
                            logError("Item \(vnum): 'посох.заклинания': invalid spell or spell level: \(key)=\(value.unwrapOptional)")
                            continue
                    }
                    extraData.spellsAndLevels[spell] = level
                }
            }
            if let maximumCharges = entity["посох.заряды", i]?.uint8 {
                let extraData: ItemExtraData.Staff = findOrCreateExtraData()
                extraData.chargesLeft = maximumCharges
                extraData.maximumCharges = maximumCharges
            }
            if let chargesLeft = entity["посох.осталось", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Staff).chargesLeft = chargesLeft
            }
        }
        for i in entity.structureIndexes("оружие") {
            if let damage = entity["оружие.вред", i]?.dice?.intDice {
                (findOrCreateExtraData() as ItemExtraData.Weapon).damage = damage
            }
            if let weaponType = entity["оружие.удар", i]?.uint16 {
                (findOrCreateExtraData() as ItemExtraData.Weapon).weaponType = WeaponType(rawValue: weaponType) ?? .bareHand
            }
            if let poisonLevel = entity["оружие.яд", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Weapon).poisonLevel = poisonLevel
            }
            if let magicalityLevel = entity["оружие.волшебство", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Weapon).magicalityLevel = magicalityLevel
            }
        }
        for i in entity.structureIndexes("доспех") {
            if let armorClass = entity["доспех.прочность", i]?.int {
                (findOrCreateExtraData() as ItemExtraData.Armor).armorClass = armorClass
            }
        }
        for i in entity.structureIndexes("зелье") {
            if let spellsAndLevels = entity["зелье.заклинания", i]?.dictionary {
                let extraData: ItemExtraData.Potion = findOrCreateExtraData()
                for (key, value) in spellsAndLevels {
                    guard let spellRaw = UInt16(exactly: key), let levelRaw = value,
                        let level = UInt8(exactly: levelRaw), let spell = Spell(rawValue: spellRaw)
                        else {
                            logError("Item \(vnum): 'зелье.заклинания': invalid spell or spell level: \(key)=\(value.unwrapOptional)")
                            continue
                    }
                    extraData.spellsAndLevels[spell] = level
                }
            }
        }
        for i in entity.structureIndexes("контейнер") {
            if let capacity = entity["контейнер.вместимость", i]?.int {
                (findOrCreateExtraData() as ItemExtraData.Container).capacity = capacity
            }
            if let flags = entity["контейнер.свойства", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Container).flags = ContainerFlags(rawValue: flags)
            }
            if let keyVnum = entity["контейнер.ключ", i]?.int {
                (findOrCreateExtraData() as ItemExtraData.Container).keyVnum = keyVnum
            }
            if let poisonLevel = entity["контейнер.яд", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Container).poisonLevel = poisonLevel
            }
            if let mobileVnum = entity["контейнер.монстр", i]?.int {
                (findOrCreateExtraData() as ItemExtraData.Container).mobileVnum = mobileVnum
            }
            if let lockDifficulty = entity["контейнер.замок_сложность", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Container).lockDifficulty = lockDifficulty
            }
            if let lockConditionRaw = entity["контейнер.замок_состояние", i]?.uint8,
                    let lockCondition = LockCondition(rawValue: lockConditionRaw) {
                (findOrCreateExtraData() as ItemExtraData.Container).lockCondition = lockCondition
            }
            if let lockDamage = entity["контейнер.замок_повреждение", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Container).lockDamage = lockDamage
            }
        }
        for i in entity.structureIndexes("записка") {
            if let text = entity["записка.текст", i]?.stringArray {
                (findOrCreateExtraData() as ItemExtraData.Note).text = text
            }
        }
        for i in entity.structureIndexes("сосуд") {
            if let totalCapacity = entity["сосуд.емкость", i]?.uint8 {
                let extraData: ItemExtraData.Vessel = findOrCreateExtraData()
                extraData.totalCapacity = totalCapacity
                extraData.usedCapacity = totalCapacity
            }
            if let usedCapacity = entity["сосуд.осталось", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Vessel).usedCapacity = usedCapacity
            }
            if let liquidRaw = entity["сосуд.жидкость", i]?.uint8,
                    let liquid = Liquid(rawValue: liquidRaw) {
                (findOrCreateExtraData() as ItemExtraData.Vessel).liquid = liquid
            }
            if let poison = entity["сосуд.яд", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Vessel).poisonLevel = poison
            }
        }
        for i in entity.structureIndexes("пища") {
            if let satiation = entity["пища.насыщение", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Food).satiation = satiation
            }
            if let moisture = entity["пища.влажность", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Food).moisture = moisture
            }
            if let poison = entity["пища.яд", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Food).poisonLevel = poison
            }
        }
        for i in entity.structureIndexes("деньги") {
            if let amount = entity["деньги.сумма", i]?.int {
                (findOrCreateExtraData() as ItemExtraData.Money).amount = amount
            }
        }
        for i in entity.structureIndexes("фонтан") {
            if let totalCapacity = entity["фонтан.емкость", i]?.uint8 {
                let extraData: ItemExtraData.Fountain = findOrCreateExtraData()
                extraData.totalCapacity = totalCapacity
                extraData.usedCapacity = totalCapacity
            }
            if let usedCapacity = entity["фонтан.осталось", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Fountain).usedCapacity = usedCapacity
            }
            if let liquidRaw = entity["фонтан.жидкость", i]?.uint8,
                    let liquid = Liquid(rawValue: liquidRaw) {
                (findOrCreateExtraData() as ItemExtraData.Fountain).liquid = liquid
            }
            if let poison = entity["фонтан.яд", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Fountain).poisonLevel = poison
            }
        }
        for i in entity.structureIndexes("книга") {
            if let spellsAndChances = entity["книга.заклинания", i]?.dictionary {
                let extraData: ItemExtraData.Spellbook = findOrCreateExtraData()
                for (key, value) in spellsAndChances {
                    guard let spellRaw = UInt16(exactly: key), let spell = Spell(rawValue: spellRaw) else {
                        logError("Item \(vnum): 'книга.заклинания': invalid spell: \(key)")
                        continue
                        
                    }
                    let chance: UInt8
                    if let chanceRaw = value {
                        guard let chanceFinal = UInt8(exactly: chanceRaw) else {
                            logError("Item \(vnum): 'книга.заклинания': invalid chance: \(value.unwrapOptional)")
                            continue
                        }
                        chance = chanceFinal
                    } else {
                        chance = 1
                    }
                    extraData.spellsAndChances[spell] = chance
                }
            }
        }
        for i in entity.structureIndexes("доска") {
            if let boardTypeIndex = entity["доска.номер", i]?.int {
                (findOrCreateExtraData() as ItemExtraData.Board).boardTypeIndex = boardTypeIndex
            }
            if let readLevel = entity["доска.чтение", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Board).readLevel = readLevel
            }
            if let writeLevel = entity["доска.запись", i]?.uint8 {
                (findOrCreateExtraData() as ItemExtraData.Board).writeLevel = writeLevel
            }
        }
        for i in entity.structureIndexes("расписка") {
            if let mountVnum = entity["расписка.скакун", i]?.int {
                (findOrCreateExtraData() as ItemExtraData.Receipt).mountVnum = mountVnum
            }
            if let stablemanVnums = entity["расписка.конюхи"]?.list {
                (findOrCreateExtraData() as ItemExtraData.Receipt).stablemanVnums.formUnion(stablemanVnums.compactMap {
                    guard let stablemanVnum = Int(exactly: $0) else {
                        logError("Item \(vnum): 'расписка.конюхи': \($0) is out of range")
                        return nil
                    }
                    return stablemanVnum
                })
            }
            if let stableRoomVnum = entity["расписка.конюшня", i]?.int {
                (findOrCreateExtraData() as ItemExtraData.Receipt).stableRoomVnum = stableRoomVnum
            }
        }

        // MARK: Other optional fields

        if let applies = entity["влияние"]?.dictionary {
            for (key, value) in applies {
                guard let applyRaw = UInt16(exactly: key),
                        let modifierRaw = value,
                        let apply = Apply(rawValue: applyRaw),
                        let modifier = Int8(exactly: modifierRaw) else {
                    logError("Item \(vnum): 'влияние': invalid apply or modifier: \(key)=\(value.unwrapOptional)")
                    continue
                }
                self.applies[apply] = modifier
            }
        }
        coinsToLoad = entity["деньги"]?.int
        decayTimerTics = entity["жизнь"]?.int
        do {
            restrictFlags = ItemAccessFlags(rawValue: entity["запрет"]?.uint32 ?? 0)
            var allowFlags = ItemAccessFlags(rawValue: entity["разрешение"]?.uint32 ?? 0)
            // If none of flags in a subgroup were specified, allow all of them for that subgroup:
            if !allowFlags.contains(anyOf: ItemAccessFlags.alignmentMask) {
                allowFlags.formUnion(ItemAccessFlags.alignmentMask)
            }
            if !allowFlags.contains(anyOf: ItemAccessFlags.classGroupMask) {
                allowFlags.formUnion(ItemAccessFlags.classGroupMask)
            }
            //if !allowFlags.contains(anyOf: ItemAccessFlags.genderMask) {
            //    allowFlags.formUnion(ItemAccessFlags.genderMask)
            //}
            if !allowFlags.contains(anyOf: ItemAccessFlags.raceMask) {
                allowFlags.formUnion(ItemAccessFlags.raceMask)
            }
            // Invert to get restrictFlags, but keep only existing flags after inverting:
            restrictFlags.formUnion(
                ItemAccessFlags(rawValue: ~allowFlags.rawValue).intersection(ItemAccessFlags.all)
            )
        }
        legend = entity["знание"]?.stringArray ?? []
        wearPercentage = entity["износ"]?.uint8
        wearFlags = ItemWearFlags(rawValue: entity["использование"]?.uint32 ?? 0)
        qualityPercentage = entity["качество"]?.uint16
        
        // MARK: Rest of the fields
        for i in entity.structureIndexes("пперехват") {
            guard let eventIdValue = entity["пперехват.событие", i]?.uint16,
                    let eventId = ItemEventId(rawValue: eventIdValue) else {
                assertionFailure()
                continue
            }
            var eventOverride = Event<ItemEventId>(eventId: eventId)
            
            if let actionFlagsValue = entity["пперехват.выполнение", i]?.uint8 {
                eventOverride.actionFlags = EventActionFlags(rawValue: actionFlagsValue)
            }
            
            if let toPlayer = entity["пперехват.игроку", i]?.string {
                eventOverride.toActor = toPlayer
            }
            if let toVictim = entity["пперехват.жертве", i]?.string {
                eventOverride.toVictim = toVictim
            }
            if let toRoomExcludingActor = entity["пперехват.комнате", i]?.string {
                eventOverride.toRoomExcludingActor = toRoomExcludingActor
            }
            
            eventOverrides.append(eventOverride)
        }
        repairCompexity = entity["починка"]?.uint8
        maximumCountInWorld = entity["предел"]?.int
        if let procedures = entity["процедура"]?.list {
            self.procedures = Set(procedures.compactMap {
                guard let procedure = Int(exactly: $0) else {
                    logError("Item \(vnum): 'процедура': \($0) is out of range")
                    return nil
                }
                return procedure
            })
        }
        if let affects = entity["пэффекты"]?.list {
            self.affects = Set(affects.compactMap {
                guard let affectTypeRaw = UInt8(exactly: $0),
                        let affectType = AffectType(rawValue: affectTypeRaw) else {
                    logError("Item \(vnum): 'пэффекты': invalid affect: \($0)")
                    return nil
                }
                return affectType
            })
        }
        if let items = entity["содержимое"]?.dictionary {
            for (vnumRaw, countRawOrNil) in items {
                guard let itemVnum = Int(exactly: vnumRaw) else {
                    logError("Item \(vnum): 'содержимое': invalid item vnum \(vnumRaw)")
                    continue
                }
                let countRaw = countRawOrNil ?? 1
                guard let count = Int(exactly: countRaw),
                    count > 0 else {
                        logError("Mobile.init(): 'содержимое': item vnum \(vnum): invalid count \(countRaw)")
                        continue
                }
                contentsToLoadCountByVnum[itemVnum] = count
            }
        }
        if let cost = entity["цена"]?.int {
            self.cost = cost
        }
        if let loadChancePercentage = entity["шанс"]?.uint8 {
            self.loadChancePercentage = loadChancePercentage
        }
    }

    func save(for style: Value.FormattingStyle, with definitions: Definitions) -> String {
        // MARK: Key fields
        
        var result = "ПРЕДМЕТ \(Value(number: vnum).formatted(for: style))\n"
        let names = endings.compress(
            names: [nameNominative, nameGenitive, nameDative, nameAccusative, nameInstrumental, namePrepositional],
            isAnimate: extraFlags.contains(.animate))
        result += "  НАЗВАНИЕ \(Value(line: names).formatted(for: style))\n"
        if !comment.isEmpty {
            result += "  КОММЕНТАРИЙ \(Value(longText: comment).formatted(for: style, continuationIndent: 14))\n"
        }
        if !synonyms.isEmpty {
            result += "  СИНОНИМЫ \(Value(line: synonyms).formatted(for: style))\n"
        }
        if !groundDescription.isEmpty {
            result += "  СТРОКА \(Value(line: groundDescription).formatted(for: style))\n"
        }
        result += "  ОПИСАНИЕ \(Value(longText: description).formatted(for: style, continuationIndent: 11))\n"
        for extra in extraDescriptions {
            result += structureIfNotEmpty("ДОПОЛНИТЕЛЬНО") { content in
                if !extra.keyword.isEmpty {
                    content += "    КЛЮЧ \(Value(line: extra.keyword).formatted(for: style))\n"
                }
                if !extra.description.isEmpty {
                    content += "    ТЕКСТ \(Value(longText: extra.description).formatted(for: style, continuationIndent: 10))\n"
                }
            }
        }
        if let gender = gender {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["род"]
            result += "  РОД \(Value(enumeration: gender).formatted(for: style, enumSpec: enumSpec))\n"
            
        }
        do {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["материал"]
            result += "  МАТЕРИАЛ \(Value(enumeration: material).formatted(for: style, enumSpec: enumSpec))\n"
        }
        result += "  ВЕС \(Value(number: weight).formatted(for: style))\n"

        // MARK: Item types
        
        if !extraDataByItemType.isEmpty {
            let itemTypes = Set(extraDataByItemType.keys.map { Int64($0.rawValue) })
            let enumSpec = definitions.enumerations.enumSpecsByAlias["тип"]
            result += "  ТИП \(Value(list: itemTypes).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if let light: ItemExtraData.Light = extraData() {
            result += structureIfNotEmpty("СВЕТ") { content in
                if light.ticsLeft != ItemExtraData.Light.defaults.ticsLeft {
                    content += "    ВРЕМЯ \(Value(number: light.ticsLeft).formatted(for: style))\n"
                }
            }
        }
        if let scroll: ItemExtraData.Scroll = extraData() {
            result += structureIfNotEmpty("СВИТОК") { content in
                if !scroll.spellsAndLevels.isEmpty {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["свиток.заклинания"]
                    content += "    ЗАКЛИНАНИЯ \(Value(dictionary: scroll.spellsAndLevels).formatted(for: style, enumSpec: enumSpec))\n"
                }
            }
        }
        if let wand: ItemExtraData.Wand = extraData() {
            result += structureIfNotEmpty("ПАЛОЧКА") { content in
                if !wand.spellsAndLevels.isEmpty {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["палочка.заклинания"]
                    content += "    ЗАКЛИНАНИЯ \(Value(dictionary: wand.spellsAndLevels).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if wand.maximumCharges != ItemExtraData.Wand.defaults.maximumCharges {
                    content += "    ЗАРЯДЫ \(Value(number: wand.maximumCharges).formatted(for: style))\n"
                }
                if wand.chargesLeft != wand.maximumCharges {
                    content += "    ОСТАЛОСЬ \(Value(number: wand.chargesLeft).formatted(for: style))\n"
                }
            }
        }
        if let staff: ItemExtraData.Staff = extraData() {
            result += structureIfNotEmpty("ПОСОХ") { content in
                if !staff.spellsAndLevels.isEmpty {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["посох.заклинания"]
                    content += "    ЗАКЛИНАНИЯ \(Value(dictionary: staff.spellsAndLevels).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if staff.maximumCharges != ItemExtraData.Staff.defaults.maximumCharges {
                    content += "    ЗАРЯДЫ \(Value(number: staff.maximumCharges).formatted(for: style))\n"
                }
                if staff.chargesLeft != staff.maximumCharges {
                    content += "    ОСТАЛОСЬ \(Value(number: staff.chargesLeft).formatted(for: style))\n"
                }
            }
        }
        if let weapon: ItemExtraData.Weapon = extraData() {
            result += structureIfNotEmpty("ОРУЖИЕ") { content in
                if !weapon.damage.isZero {
                    content += "    ВРЕД \(Value(dice: weapon.damage).formatted(for: style))\n"
                }
                if weapon.weaponType != ItemExtraData.Weapon.defaults.weaponType {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["оружие.тип"]
                    content += "    ТИП \(Value(enumeration: weapon.weaponType).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if weapon.poisonLevel != ItemExtraData.Weapon.defaults.poisonLevel {
                    content += "    ЯД \(Value(number: weapon.poisonLevel).formatted(for: style))\n"
                }
                if weapon.magicalityLevel != ItemExtraData.Weapon.defaults.magicalityLevel {
                    content += "    ВОЛШЕБСТВО \(Value(number: weapon.magicalityLevel).formatted(for: style))\n"
                }
            }
        }
        if let armor: ItemExtraData.Armor = extraData() {
            result += structureIfNotEmpty("ДОСПЕХ") { content in
                if armor.armorClass != ItemExtraData.Armor.defaults.armorClass {
                    content += "    ПРОЧНОСТЬ \(Value(number: armor.armorClass).formatted(for: style))\n"
                }
            }
        }
        if let potion: ItemExtraData.Potion = extraData() {
            result += structureIfNotEmpty("ЗЕЛЬЕ") { content in
                if !potion.spellsAndLevels.isEmpty {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["зелье.заклинания"]
                    content += "    ЗАКЛИНАНИЯ \(Value(dictionary: potion.spellsAndLevels).formatted(for: style, enumSpec: enumSpec))\n"
                }
            }
        }
        if let container: ItemExtraData.Container = extraData() {
            result += structureIfNotEmpty("КОНТЕЙНЕР") { content in
                if container.capacity != ItemExtraData.Container.defaults.capacity {
                    content += "    ВМЕСТИМОСТЬ \(Value(number: container.capacity).formatted(for: style))\n"
                }
                if container.flags != ItemExtraData.Container.defaults.flags {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["контейнер.свойства"]
                    content += "    СВОЙСТВА \(Value(flags: container.flags).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if container.keyVnum != ItemExtraData.Container.defaults.keyVnum {
                    content += "    КЛЮЧ \(Value(number: container.keyVnum).formatted(for: style))\n"
                }
                if container.poisonLevel != ItemExtraData.Container.defaults.poisonLevel {
                    content += "    ЯД \(Value(number: container.poisonLevel).formatted(for: style))\n"
                }
                if container.mobileVnum != ItemExtraData.Container.defaults.mobileVnum {
                    content += "    МОНСТР \(Value(number: container.mobileVnum).formatted(for: style))\n"
                }
                if container.lockDifficulty != ItemExtraData.Container.defaults.lockDifficulty {
                    content += "    ЗАМОК_СЛОЖНОСТЬ \(Value(number: container.lockDifficulty).formatted(for: style))\n"
                }
                if container.lockCondition != ItemExtraData.Container.defaults.lockCondition {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["контейнер.замок_состояние"]
                    content += "    ЗАМОК_СОСТОЯНИЕ \(Value(enumeration: container.lockCondition).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if container.lockDamage != ItemExtraData.Container.defaults.lockDamage {
                    content += "    ЗАМОК_ПОВРЕЖДЕНИЕ \(Value(number: container.lockDamage).formatted(for: style))\n"
                }
            }
        }
        if let note: ItemExtraData.Note = extraData() {
            result += structureIfNotEmpty("ЗАПИСКА") { content in
                if note.text != ItemExtraData.Note.defaults.text {
                    content += "    ТЕКСТ \(Value(longText: note.text).formatted(for: style, continuationIndent: 8))\n"
                }
            }
        }
        if let vessel: ItemExtraData.Vessel = extraData() {
            result += structureIfNotEmpty("СОСУД") { content in
                if vessel.totalCapacity != ItemExtraData.Vessel.defaults.totalCapacity {
                    content += "    ЕМКОСТЬ \(Value(number: vessel.totalCapacity).formatted(for: style))\n"
                }
                if vessel.usedCapacity != vessel.totalCapacity {
                    content += "    ОСТАЛОСЬ \(Value(number: vessel.usedCapacity).formatted(for: style))\n"
                }
                if vessel.liquid != ItemExtraData.Vessel.defaults.liquid {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["сосуд.жидкость"]
                    content += "    ЖИДКОСТЬ \(Value(enumeration: vessel.liquid).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if vessel.poisonLevel != ItemExtraData.Vessel.defaults.poisonLevel {
                    content += "    ЯД \(Value(number: vessel.poisonLevel).formatted(for: style))\n"
                }
            }
        }
        if let food: ItemExtraData.Food = extraData() {
            result += structureIfNotEmpty("ПИЩА") { content in
                if food.satiation != ItemExtraData.Food.defaults.satiation {
                    content += "    НАСЫЩЕНИЕ \(Value(number: food.satiation).formatted(for: style))\n"
                }
                if food.moisture != ItemExtraData.Food.defaults.moisture {
                    content += "    ВЛАЖНОСТЬ \(Value(number: food.moisture).formatted(for: style))\n"
                }
                if food.poisonLevel != ItemExtraData.Food.defaults.poisonLevel {
                    content += "    ЯД \(Value(number: food.poisonLevel).formatted(for: style))\n"
                }
            }
        }
        if let money: ItemExtraData.Money = extraData() {
            result += structureIfNotEmpty("ДЕНЬГИ") { content in
                if money.amount != ItemExtraData.Money.defaults.amount {
                    content += "    СУММА \(Value(number: money.amount).formatted(for: style))\n"
                }
            }
        }
        if let fountain: ItemExtraData.Fountain = extraData() {
            result += structureIfNotEmpty("ФОНТАН") { content in
                if fountain.totalCapacity != ItemExtraData.Fountain.defaults.totalCapacity {
                    content += "    ЕМКОСТЬ \(Value(number: fountain.totalCapacity).formatted(for: style))\n"
                }
                if fountain.usedCapacity != fountain.totalCapacity {
                    content += "    ОСТАЛОСЬ \(Value(number: fountain.usedCapacity).formatted(for: style))\n"
                }
                if fountain.liquid != ItemExtraData.Fountain.defaults.liquid {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["фонтан.жидкость"]
                    content += "    ЖИДКОСТЬ \(Value(enumeration: fountain.liquid).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if fountain.poisonLevel != ItemExtraData.Fountain.defaults.poisonLevel {
                    content += "    ЯД \(Value(number: fountain.poisonLevel).formatted(for: style))\n"
                }
            }
        }
        if let spellbook: ItemExtraData.Spellbook = extraData() {
            result += structureIfNotEmpty("КНИГА") { content in
                if !spellbook.spellsAndChances.isEmpty {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["книга.заклинания"]
                    content += "    ЗАКЛИНАНИЯ \(Value(dictionary: spellbook.spellsAndChances).formatted(for: style, enumSpec: enumSpec))\n"
                }
            }
        }
        if let board: ItemExtraData.Board = extraData() {
            result += structureIfNotEmpty("ДОСКА") { content in
                if board.boardTypeIndex != ItemExtraData.Board.defaults.boardTypeIndex {
                    content += "    НОМЕР \(Value(number: board.boardTypeIndex).formatted(for: style))\n"
                }
                if board.readLevel != ItemExtraData.Board.defaults.readLevel {
                    content += "    ЧТЕНИЕ \(Value(number: board.readLevel).formatted(for: style))\n"
                }
                if board.writeLevel != ItemExtraData.Board.defaults.writeLevel {
                    content += "    ЗАПИСЬ \(Value(number: board.writeLevel).formatted(for: style))\n"
                }
            }
        }
        if let receipt: ItemExtraData.Receipt = extraData() {
            result += structureIfNotEmpty("РАСПИСКА") { content in
                if receipt.mountVnum != ItemExtraData.Receipt.defaults.mountVnum {
                    content += "    СКАКУН \(Value(number: receipt.mountVnum).formatted(for: style))\n"
                }
                if receipt.stablemanVnums != ItemExtraData.Receipt.defaults.stablemanVnums {
                    content += "    КОНЮХИ \(Value(list: receipt.stablemanVnums).formatted(for: style))\n"
                }
                if receipt.stableRoomVnum != ItemExtraData.Receipt.defaults.stableRoomVnum {
                    content += "    КОНЮШНЯ \(Value(number: receipt.stableRoomVnum).formatted(for: style))\n"
                }
            }
        }

        // MARK: Other optional fields
        
        if !applies.isEmpty {
            let keysAndValues: [(Int64, Int64)] = applies.map { (Int64($0.key.rawValue), Int64($0.value)) }
            let appliesAndModifiers = [Int64: Int64](keysAndValues, uniquingKeysWith: { $0 + $1 })
            let enumSpec = definitions.enumerations.enumSpecsByAlias["влияние"]
            result += "  ВЛИЯНИЕ \(Value(dictionary: appliesAndModifiers).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if let coinsToLoad = coinsToLoad {
            result += "  ДЕНЬГИ \(Value(number: coinsToLoad).formatted(for: style))\n"
        }
        if let decayTimerTics = decayTimerTics {
            result += "  ЖИЗНЬ \(Value(number: decayTimerTics).formatted(for: style))\n"
        }
        do {
            let allowFlags = ItemAccessFlags(rawValue: ~restrictFlags.rawValue).intersection(ItemAccessFlags.all)
            var resultingRestrictFlags: ItemAccessFlags = []
            var resultingAllowFlags: ItemAccessFlags = []
            
            // Full "restrict" set case would produce empty "allow" set, which is invalid,
            // so fallback to "restrict" in these cases too.
            if restrictFlags.alignmentSetBitsCount() == ItemAccessFlags.alignmentTotalBitsCount ||
                    restrictFlags.alignmentSetBitsCount() <= ItemAccessFlags.alignmentTotalBitsCount / 2 {
                resultingRestrictFlags.formUnion(restrictFlags.intersection(.alignmentMask))
            } else {
                resultingAllowFlags.formUnion(allowFlags.intersection(.alignmentMask))
            }

            if restrictFlags.classGroupSetBitsCount() == ItemAccessFlags.classGroupTotalBitsCount ||
                restrictFlags.classGroupSetBitsCount() <= ItemAccessFlags.classGroupTotalBitsCount / 2 {
                resultingRestrictFlags.formUnion(restrictFlags.intersection(.classGroupMask))
            } else {
                resultingAllowFlags.formUnion(allowFlags.intersection(.classGroupMask))
            }

            if restrictFlags.raceSetBitsCount() == ItemAccessFlags.raceTotalBitsCount ||
                restrictFlags.raceSetBitsCount() <= ItemAccessFlags.raceTotalBitsCount / 2 {
                resultingRestrictFlags.formUnion(restrictFlags.intersection(.raceMask))
            } else {
                resultingAllowFlags.formUnion(allowFlags.intersection(.raceMask))
            }

            if !resultingRestrictFlags.isEmpty {
                let enumSpec = definitions.enumerations.enumSpecsByAlias["запрет"]
                result += "  ЗАПРЕТ \(Value(flags: resultingRestrictFlags).formatted(for: style, enumSpec: enumSpec))\n"
            }
            if !resultingAllowFlags.isEmpty {
                let enumSpec = definitions.enumerations.enumSpecsByAlias["разрешение"]
                result += "  РАЗРЕШЕНИЕ \(Value(flags: resultingAllowFlags).formatted(for: style, enumSpec: enumSpec))\n"
            }
        }
        if !legend.isEmpty {
            result += "  ЗНАНИЕ \(Value(longText: legend).formatted(for: style, continuationIndent: 9))\n"
        }
        if let wearPercentage = wearPercentage {
            result += "  ИЗНОС \(Value(number: wearPercentage).formatted(for: style))\n"
        }
        if !wearFlags.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["использование"]
            result += "  ИСПОЛЬЗОВАНИЕ \(Value(flags: wearFlags).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if let qualityPercentage = qualityPercentage {
            result += "  КАЧЕСТВО \(Value(number: qualityPercentage).formatted(for: style))\n"
        }
        
        for event in eventOverrides {
            result += structureIfNotEmpty("ППЕРЕХВАТ") { content in
                do {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["пперехват.событие"]
                    content += "    СОБЫТИЕ \(Value(enumeration: event.eventId).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if !event.actionFlags.isEmpty {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["пперехват.выполнение"]
                    content += "    ВЫПОЛНЕНИЕ \(Value(flags: event.actionFlags).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if let toActor = event.toActor {
                    content += "    ИГРОКУ \(Value(line: toActor).formatted(for: style))\n"
                }
                if let toVictim = event.toVictim {
                    content += "    ЖЕРТВЕ \(Value(line: toVictim).formatted(for: style))\n"
                }
                if let toRoomExcludingActor = event.toRoomExcludingActor {
                    content += "    КОМНАТЕ \(Value(line: toRoomExcludingActor).formatted(for: style))\n"
                }
            }
        }
        if let repairComplexity = repairCompexity {
            result += "  ПОЧИНКА \(Value(number: repairComplexity).formatted(for: style))\n"
        }
        if let loadMaximum = maximumCountInWorld {
            result += "  ПРЕДЕЛ \(Value(number: loadMaximum).formatted(for: style))\n"
        }
        if !procedures.isEmpty {
            result += "  ПРОЦЕДУРА \(Value(list: procedures).formatted(for: style))\n"
        }
        if !affects.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["пэффекты"]
            result += "  ПЭФФЕКТЫ \(Value(list: affects).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if !extraFlags.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["псвойства"]
            result += "  ПСВОЙСТВА \(Value(flags: extraFlags).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if !contentsToLoadCountByVnum.isEmpty {
            let contentsToLoad = contentsToLoadCountByVnum.mapValues { $0 != 1 ? $0 : nil } // use short form
            result += "  СОДЕРЖИМОЕ \(Value(dictionary: contentsToLoad).formatted(for: style))\n"

        }
        if let cost = cost {
            result += "  ЦЕНА \(Value(number: cost).formatted(for: style))\n"
        }
        if let loadChancePercentage = loadChancePercentage {
            result += "  ШАНС \(Value(number: loadChancePercentage).formatted(for: style))\n"
        }
        return result
    }
    
    func hasType(_ itemType: ItemType) -> Bool {
        return extraDataByItemType[itemType] != nil
    }

    func extraData<T: ItemExtraDataType>() -> T? {
        guard let data = extraDataByItemType[T.itemType] else { return nil }
        guard let casted = data as? T else {
            assertionFailure()
            return nil
        }
        return casted
    }
    
    private func findOrCreateExtraData<T: ItemExtraDataType>() -> T {
        if let data = extraDataByItemType[T.itemType] {
            guard let casted = data as? T else { fatalError() }
            return casted
        }
        let extraData = T.init()
        extraDataByItemType[T.itemType] = extraData
        return extraData
    }
    
    func checkMaximumAndLoadChances() -> Bool {
        return canLoadMoreItems() && checkLoadChances()
    }
    
    private func canLoadMoreItems() -> Bool {
        guard let loadMaximum = maximumCountInWorld else {
            return true
        }
        return (db.itemsCountByVnum[vnum] ?? 0) < loadMaximum
    }
    
    private func checkLoadChances() -> Bool {
        let loadChance = loadChancePercentage ?? 100
        guard loadChance < 100 else { return true }
        return Random.uniformInt(1...100) <= loadChance
    }
}
