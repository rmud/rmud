import Foundation

class MobilePrototype {
    var vnum: Int // Required
    var flags: MobileFlags = [] // Optional
    var nameNominative: String // Required
    var nameGenitive: String // Required
    var nameDative: String // Required
    var nameAccusative: String // Required
    var nameInstrumental: String // Required
    var namePrepositional: String // Required
    var comment: [String] // Optional
    var synonyms: String // Optional
    var groundDescription: String // Required. For "look at room"
    var description: [String] // Required. Detailed description. For "look mobile"
    var extraDescriptions: [ExtraDescription] = [] // Optional
    var race: Race // Required
    var gender: Gender // Required
    var classId: ClassId // Required
    var alignment: Alignment // Required
    var level: UInt8 // Required
    var experience: Int // Required
    var maximumHitPoints: Int // Required
    var defense: Int // Required
    var attack: Int // Required
    var absorb: Int? // Optional
    var damage1: Dice<Int8> // Required
    var hitType1: HitType? // Optional
    var attacks1: UInt8? // Optional
    var damage2: Dice<Int8>? // Optional
    var hitType2: HitType? // Optional
    var attacks2: UInt8? // Optional

    // The rest are optional
    var grip: UInt8? // Interferes with rescuing and fleeing, 0..100
    var corpsePoisonLevel: UInt8? // Uneatable mobs with poison in blood
    var movementType: MovementType?
    var path = ""
    var defaultPosition: Position?
    var maximumCountInWorld: UInt8?
    var loadChancePercentage: UInt8?
    var loadCommand: String // FIXME: deprecated
    var loadEquipmentWhereByVnum: [Int: EquipWhere] = [:] // Equip mob with this stuff on load
    var loadInventoryCountByVnum: [Int: Int] = [:]
    var loadItemsOnDeathCountByVnum: [Int: Int] = [:] // Put this stuff into corpse
    var loadMoney: Dice<Int>?
    var wimpLevel: UInt8?
    var procedures: Set<Int> = []
    var strength: UInt8?
    var intelligence: UInt8?
    var wisdom: UInt8?
    var dexterity: UInt8?
    var constitution: UInt8?
    var charisma: UInt8?
    var size: UInt8?
    var health: UInt8?
    var weight: UInt?
    var height: UInt?
    var weaponImmunityPercentage: UInt8?
    var skillKnowledgeLevels: [Skill: UInt8?] = [:] // nil - level based
    var spellsKnown: Set<Spell> = []
    var spellsToMemorize: [Spell: UInt8] = [:]
    var affects: Set<AffectType> = []
    var eventOverrides: [Event<MobileEventId>] = []
    var specialAttacks: [SpecialAttack] = []
    var shopkeeper: Shopkeeper?
    var stablemanNoteVnum: Int? // FIXME: make mobile types similar to item types
    var saves: [Frag: Int16] = [:]
    var corpseVnum: Int?
    var corpse: Corpse?
    
    init?(entity: Entity) {
        // MARK: Key fields

        // Required:
        guard let vnum = entity["монстр"]?.int else {
            assertionFailure()
            return nil
        }
        
        self.vnum = vnum
        // We need to parse flags this early because of 'inanimate' flag
        flags = MobileFlags(rawValue: entity["мсвойства"]?.uint32 ?? 0)
        var name = entity["имя"]?.string ?? "Без имени"
        if name.contains("[") {
            flags.insert(.inanimate)
            name = name
                .replacingOccurrences(of: "[", with: "(")
                .replacingOccurrences(of: "]", with: ")")
        }
        let names = endings.decompress(names: name,
                                       isAnimate: !flags.contains(.inanimate))
        nameNominative = names[0]
        nameGenitive = names[1]
        nameDative = names[2]
        nameAccusative = names[3]
        nameInstrumental = names[4]
        namePrepositional = names[5]
        comment = entity["комментарий"]?.stringArray ?? []
        synonyms = entity["синонимы"]?.string ?? ""
        groundDescription = entity["строка"]?.string ?? "Монстр без описания."
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
        race = entity["раса"]?.uint8.flatMap { Race(rawValue: $0) } ?? .monster
        gender = entity["пол"]?.uint8.flatMap { Gender(rawValue: $0) } ?? .masculine
        classId = entity["профессия"]?.uint8.flatMap { ClassId(rawValue: $0) } ?? .amalgamated // FIXME: introduce 'none'
        alignment = Alignment(clamping: entity["наклонности"]?.int ?? 0)
        level = entity["уровень"]?.uint8 ?? 0
        experience = entity["опыт"]?.int ?? 0
        maximumHitPoints = entity["жизнь"]?.int ?? 0
        defense = entity["защита"]?.int ?? 0
        attack = entity["атака"]?.int ?? 0
        if let absorb = entity["поглощение"]?.int {
            self.absorb = absorb
        }
        damage1 = entity["вред1"]?.dice?.int8Dice ?? Dice()
        if let hitType1 = entity["удар1"]?.uint8.flatMap({ HitType(rawValue: $0) }) {
            self.hitType1 = hitType1
        }
        if var attacks1 = entity["атаки1"]?.int8 {
            if attacks1 < 0 {
                flags.insert(.switchTarget)
                attacks1 = -attacks1
            }
            self.attacks1 = UInt8(attacks1)
        }
        if let damage2 = entity["вред2"]?.dice?.int8Dice {
            self.damage2 = damage2
        }
        if let hitType2 = entity["удар2"]?.uint8.flatMap({ HitType(rawValue: $0) }) {
            self.hitType2 = hitType2
        }
        if let attacks2 = entity["атаки2"]?.uint8 {
            self.attacks2 = attacks2
        }

        
        
        // MARK: Other optional fields
        grip = entity["хватка"]?.uint8
        corpsePoisonLevel = entity["яд"]?.uint8
        movementType = entity["перемещение"]?.uint8.flatMap { MovementType(rawValue: $0) }
        path = entity["путь"]?.string ?? ""
        defaultPosition = entity["положение"]?.uint8.flatMap { Position(rawValue: $0) }
        maximumCountInWorld = entity["предел"]?.uint8
        loadChancePercentage = entity["шанс"]?.uint8
        loadCommand = entity["команда"]?.string ?? ""

        if let equipment = entity["экипировка"]?.dictionary {
            for (vnumRaw, positionRaw) in equipment {
                guard let vnum = Int(exactly: vnumRaw) else {
                    logError("MobilePrototype.init(): invalid vnum \(vnumRaw)")
                    continue
                }

                let equipWhere: EquipWhere
                if let positionRaw = positionRaw {
                    guard let positionRawInt8 = Int8(exactly: positionRaw),
                        let position = EquipmentPosition(rawValue: positionRawInt8) else {
                            logError("Mobile.init(): 'экипировка': invalid item position \(positionRaw)")
                            continue
                    }
                    equipWhere = .equip(position: position)
                } else {
                    equipWhere = .equipAnywhere
                }
                assert(loadEquipmentWhereByVnum[vnum] == nil)
                loadEquipmentWhereByVnum[vnum] = equipWhere
            }
        }

        if let inventory = entity["инвентарь"]?.dictionary {
            for (vnumRaw, countRawOrNil) in inventory {
                guard let vnum = Int(exactly: vnumRaw) else {
                    logError("Mobile.init(): 'инвентарь': invalid item vnum \(vnumRaw)")
                    continue
                }
                let countRaw = countRawOrNil ?? 1
                guard let count = Int(exactly: countRaw),
                    count > 0 else {
                        logError("Mobile.init(): 'инвентарь': item vnum \(vnum): invalid count \(countRaw)")
                        continue
                }
                loadInventoryCountByVnum[vnum] = count
            }
        }

        if let onDeath = entity["посмертно"]?.dictionary {
            for (vnumRaw, countRawOrNil) in onDeath {
                guard let vnum = Int(exactly: vnumRaw) else {
                    logError("Mobile.init(): 'посмертно': invalid item vnum \(vnumRaw)")
                    continue
                }
                let countRaw = countRawOrNil ?? 1
                guard let count = Int(exactly: countRaw),
                    count > 0 else {
                        logError("Mobile.init(): 'посмертно': item vnum \(vnum): invalid count \(countRaw)")
                        continue
                }
                loadItemsOnDeathCountByVnum[vnum] = count
            }
        }

        if let dice = entity["деньги"]?.dice?.intDice {
            self.loadMoney = dice
        }
        
        if let wimpLevel = entity["трусость"]?.uint8 {
            self.wimpLevel = wimpLevel
        }

        // FIXME: ensure that it's set when insantiating mobile
        // maxMovement = 50
        
        if let procedures = entity["процедура"]?.list {
            self.procedures = Set(procedures.compactMap {
                guard let procedure = Int(exactly: $0) else {
                    logError("Mobile \(vnum): 'процедура': \($0) is out of range")
                    return nil
                }
                return procedure
            })
        }

        if let strength = entity["сила"]?.uint8 {
            self.strength = strength
        }
        if let dexterity = entity["ловкость"]?.uint8 {
            self.dexterity = dexterity
        }
        if let constitution = entity["телосложение"]?.uint8 {
            self.constitution = constitution
        }
        if let intelligence = entity["разум"]?.uint8 {
            self.intelligence = intelligence
        }
        if let wisdom = entity["мудрость"]?.uint8 {
            self.wisdom = wisdom
        }
        // FIXME: charisma?
        //charisma = 13

        if let size = entity["размер"]?.uint8 {
            self.size = size
        }
        if let health = entity["здоровье"]?.uint8 {
            self.health = health
        }
        if let weight = entity["вес"]?.uint {
            self.weight = weight
        }
        if let height = entity["рост"]?.uint {
            self.height = height
        }
        // FIXME: not implemented; unintuitive var name?
        if let weaponImmunityPercentage = entity["иммунитет"]?.uint8 {
            self.weaponImmunityPercentage = weaponImmunityPercentage
        }

        if let skills = entity["умения"]?.dictionary {
            for (skillRaw, skillLevelRaw) in skills {
                guard let skillRawUInt16 = UInt16(exactly: skillRaw),
                        let skill = Skill(rawValue: skillRawUInt16) else {
                    logError("Mobile \(vnum): 'умения': invalid skill \(skillRaw)")
                    continue
                }
                if let skillLevelRaw = skillLevelRaw {
                    guard let skillLevel = UInt8(exactly: skillLevelRaw) else {
                        logError("Mobile \(vnum): 'умения': invalid skill level \(skillLevelRaw)")
                        continue
                    }
                    skillKnowledgeLevels[skill] = skillLevel
                } else {
                    skillKnowledgeLevels[skill] = nil
                }
            }
        }

        if let spells = entity["заклинания"]?.list {
            for spellRaw in spells {
                guard let spellRawUInt16 = UInt16(exactly: spellRaw),
                        let spell = Spell(rawValue: spellRawUInt16) else {
                    logError("Mobile \(vnum): 'умения': invalid spell \(spellRaw)")
                    continue
                }
                spellsKnown.insert(spell)
            }
        }

        if let memorization = entity["заучивание"]?.dictionary {
            for (spellRaw, countRaw) in memorization {
                guard let spellRawUInt16 = UInt16(exactly: spellRaw),
                    let spell = Spell(rawValue: spellRawUInt16) else {
                        logError("Mobile \(vnum): 'заучивание': invalid spell \(spellRaw)")
                        continue
                }
                if let countRaw = countRaw {
                    guard let count = UInt8(exactly: countRaw) else {
                        logError("Mobile \(vnum): 'заучивание': invalid spell count \(countRaw)")
                        continue
                    }
                    spellsToMemorize[spell] = count
                } else {
                    spellsToMemorize[spell] = 1
                }
            }
        }

        if let affects = entity["мэффекты"]?.list {
            self.affects = Set(affects.compactMap {
                guard let affectTypeRaw = UInt8(exactly: $0),
                        let affectType = AffectType(rawValue: affectTypeRaw) else {
                    logError("Mobile \(vnum): 'мэффекты': invalid affect: \($0)")
                    return nil
                }
                return affectType
            })
        }
        
        for i in entity.structureIndexes("мперехват") {
            guard let eventIdValue = entity["мперехват.событие", i]?.uint16,
                    let eventId = MobileEventId(rawValue: eventIdValue) else {
                assertionFailure()
                continue
            }
            var eventOverride = Event<MobileEventId>(eventId: eventId)
            if let actionFlagsValue = entity["мперехват.выполнение", i]?.uint8 {
                eventOverride.actionFlags = EventActionFlags(rawValue: actionFlagsValue)
            }
            if let toPlayer = entity["мперехват.игроку", i]?.string {
                eventOverride.toActor = toPlayer
            }
            if let toVictim = entity["мперехват.жертве", i]?.string {
                eventOverride.toVictim = toVictim
            }
            if let toRoomExcludingActor = entity["мперехват.комнате", i]?.string {
                eventOverride.toRoomExcludingActor = toRoomExcludingActor
            }
            
            eventOverrides.append(eventOverride)
        }
        
        for i in entity.structureIndexes("магазин") {
            var shopkeeper = self.shopkeeper ?? Shopkeeper()
            if let sellProfit = entity["магазин.продажа", i]?.int {
                shopkeeper.sellProfit = sellProfit
            }
            if let buyProfit = entity["магазин.покупка", i]?.int {
                shopkeeper.buyProfit = buyProfit
            }
            if let repairProfit = entity["магазин.починка", i]?.int {
                shopkeeper.repairProfit = repairProfit
            }
            if let repairLevel = entity["магазин.мастерство", i]?.uint8 {
                shopkeeper.repairLevel = repairLevel
            }
            if let producingItemVnums = entity["магазин.меню", i]?.list {
                shopkeeper.producingItemVnums = Set(producingItemVnums.compactMap {
                    guard let itemVnum = Int(exactly: $0) else {
                        logError("Mobile \(vnum): 'магазин.меню': \($0) is out of range")
                        return nil
                    }
                    return itemVnum
                })
            }
            if let buyingItemsOfType = entity["магазин.товар", i]?.uint32.flatMap({ ItemTypeFlagsDeprecated(rawValue: $0) }) {
                shopkeeper.buyingItemsOfType = buyingItemsOfType.itemTypes
            }
            // FIXME
            //        {"магазин.признаки",   vtLONG,  0,       &prs_shp.info, SPC_SHOP},
            // FIXME: unimplemented, not used
            // FIXME: also add РАЗРЕШЕНИЕ, reuse code from ItemPrototype
            if let restrictFlags = entity["магазин.запрет", i]?.uint32.flatMap({ ItemAccessFlags(rawValue: $0) }) {
                shopkeeper.restrictFlags = restrictFlags
            }
            self.shopkeeper = shopkeeper
        }
        if let stablemanNoteVnum = entity["конюх"]?.int {
            self.stablemanNoteVnum = stablemanNoteVnum
        }
        //        // TODO: МАГАЗИН.РАЗРЕШЕНИЕ  Б   ;Обслуживаемые покупатели
        //        //  {"магазин.уровень", vtLONG, 0, &prs_shp.repair_lev, SPC_SHOP}, // fixme? wtf

        //        /* Защищенность моба от магии - пока не реализовано :-( */
        if let savingAcid = entity["зкислота"]?.int16 {
            saves[.acid] = savingAcid
        }
        if let savingCold = entity["зхолод"]?.int16 {
            saves[.cold] = savingCold
        }
        if let savingElectricity = entity["зэлектричество"]?.int16 {
            saves[.electricity] = savingElectricity
        }
        if let savingCrush = entity["зудар"]?.int16 {
            saves[.crush] = savingCrush
        }
        if let savingHeat = entity["зогонь"]?.int16 {
            saves[.heat] = savingHeat
        }
        if let savingMagic = entity["змагия"]?.int16 {
            saves[.magic] = savingMagic
        }

        for i in entity.structureIndexes("спец") {
            guard let typeRaw = entity["спец.тип", i]?.uint8,
                    let type = SpecialAttackType(rawValue: typeRaw) else {
                assertionFailure()
                continue
            }
            var specialAttack = SpecialAttack(type: type)
            if let frag = entity["спец.разрушение", i]?.uint8.flatMap({ Frag(rawValue: $0) }) {
                specialAttack.frag = frag
            }
            if let level = entity["спец.уровень", i]?.uint8 {
                specialAttack.level = level
            }
            if let usageFlags = entity["спец.применение", i]?.uint8.flatMap({ SpecialAttackUsageFlags(rawValue: $0) }) {
                specialAttack.usageFlags = usageFlags
            }
            if let damage = entity["спец.вред", i]?.dice?.int8Dice {
                specialAttack.damage = damage
            }
            if let spell = entity["спец.заклинание", i]?.uint16.flatMap({ Spell(rawValue: $0)}) {
                specialAttack.spell = spell
            }
            if let toFoes = entity["спец.врагам", i]?.string {
                specialAttack.toFoes = toFoes
            }
            if let toFriends = entity["спец.друзьям", i]?.string {
                specialAttack.toFriends = toFriends
            }
            if let toVictim = entity["спец.игроку", i]?.string { // FIXME: rename to "жертве"
                specialAttack.toVictim = toVictim
            }
            // FIXME: also add "персонажу"
            if let toRoom = entity["спец.комнате", i]?.string {
                specialAttack.toRoom = toRoom
            }
            // TODO: А может стоило сделать "СПЕЦ.ВСЕМ" ?
            specialAttacks.append(specialAttack)
        }

        if let corpseVnum = entity["номертрупа"]?.int {
            self.corpseVnum = corpseVnum
        }

        for i in entity.structureIndexes("труп") {
            var corpse = self.corpse ?? Corpse()
            if let name = entity["труп.имя", i]?.string {
                corpse.name = name
            }
            if let synonyms = entity["труп.синонимы", i]?.string {
                corpse.synonyms = synonyms
            }
            if let groundDescription = entity["труп.строка", i]?.string {
                corpse.groundDescription = groundDescription
            }
            if let description = entity["труп.описание", i]?.stringArray {
                corpse.description = description
            }
            if let gender = entity["труп.род", i]?.uint8.flatMap({ Gender(rawValue: $0) }) {
                corpse.gender = gender
            }
            if let material = entity["труп.материал", i]?.uint8.flatMap({ Material(rawValue: $0) }) {
                corpse.material = material
            }
            self.corpse = corpse
        }
    }
    
    func save(for style: Value.FormattingStyle, with definitions: Definitions) -> String {
        // MARK: Key fields
        
        var result = "МОНСТР \(Value(number: vnum).formatted(for: style))\n"
        let names = endings.compress(
            names: [nameNominative, nameGenitive, nameDative, nameAccusative, nameInstrumental, namePrepositional],
            isAnimate: !flags.contains(.inanimate))
        result += "  ИМЯ \(Value(line: names).formatted(for: style))\n"
        if !comment.isEmpty {
            result += "  КОММЕНТАРИЙ \(Value(longText: comment).formatted(for: style, continuationIndent: 14))\n"
        }
        if !synonyms.isEmpty {
            result += "  СИНОНИМЫ \(Value(line: synonyms).formatted(for: style))\n"
        }
        result += "  СТРОКА \(Value(line: groundDescription).formatted(for: style))\n"
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
        do {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["раса"]
            result += "  РАСА \(Value(enumeration: race).formatted(for: style, enumSpec: enumSpec))\n"
        }
        do {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["пол"]
            result += "  ПОЛ \(Value(enumeration: gender).formatted(for: style, enumSpec: enumSpec))\n"
        }
        do {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["профессия"]
            result += "  ПРОФЕССИЯ \(Value(enumeration: classId).formatted(for: style, enumSpec: enumSpec))\n"
        }
        result += "  НАКЛОННОСТИ \(Value(number: alignment.value).formatted(for: style))\n"
        result += "  УРОВЕНЬ \(Value(number: level).formatted(for: style))\n"
        result += "  ОПЫТ \(Value(number: experience).formatted(for: style))\n"
        result += "  ЖИЗНЬ \(Value(number: maximumHitPoints).formatted(for: style))\n"
        result += "  ЗАЩИТА \(Value(number: defense).formatted(for: style))\n"
        result += "  АТАКА \(Value(number: attack).formatted(for: style))\n"
        if let absorb = absorb {
            result += "  ПОГЛОЩЕНИЕ \(Value(number: absorb).formatted(for: style))\n"
        }
        result += "  ВРЕД1 \(Value(dice: damage1).formatted(for: style))\n"
        if let hitType1 = hitType1 {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["удар1"]
            result += "  УДАР1 \(Value(enumeration: hitType1).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if let attacks1 = attacks1 {
            result += "  АТАКИ1 \(Value(number: attacks1).formatted(for: style))\n"
        }
        if let damage2 = damage2 {
            result += "  ВРЕД2 \(Value(dice: damage2).formatted(for: style))\n"
        }
        if let hitType2 = hitType2 {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["удар2"]
            result += "  УДАР2 \(Value(enumeration: hitType2).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if let attacks2 = attacks2 {
            result += "  АТАКИ2 \(Value(number: attacks2).formatted(for: style))\n"
        }
        
        // MARK: Other optional fields
        if let grip = grip {
            result += "  ХВАТКА \(Value(number: grip).formatted(for: style))\n"
        }
        if let corpsePoisonLevel = corpsePoisonLevel {
            result += "  ЯД \(Value(number: corpsePoisonLevel).formatted(for: style))\n"
        }
        if let movementType = movementType {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["перемещение"]
            result += "  ПЕРЕМЕЩЕНИЕ \(Value(enumeration: movementType).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if !path.isEmpty {
            result += "  ПУТЬ \(Value(line: path).formatted(for: style))\n"
        }
        if let defaultPosition = defaultPosition {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["положение"]
            result += "  ПОЛОЖЕНИЕ \(Value(enumeration: defaultPosition).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if let maximumCountInWorld = maximumCountInWorld {
            result += "  ПРЕДЕЛ \(Value(number: maximumCountInWorld).formatted(for: style))\n"
        }
        if let loadChancePercentage = loadChancePercentage {
            result += "  ШАНС \(Value(number: loadChancePercentage).formatted(for: style))\n"
        }
        if !loadCommand.isEmpty {
            result += "  КОМАНДА \(Value(line: loadCommand).formatted(for: style))\n"
        }
        if !loadEquipmentWhereByVnum.isEmpty {
            // TODO: use enumspec for wear position too
            let enumSpec = definitions.enumerations.enumSpecsByAlias["экипировка"]
            let d: [Int: Int8?] = loadEquipmentWhereByVnum.mapValues {
                switch $0 {
                case .equip(let position):
                    return position.rawValue
                case .equipAnywhere:
                    return nil
                }
            }
            result += "  ЭКИПИРОВКА \(Value(dictionary: d).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if !loadInventoryCountByVnum.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["инвентарь"]
            result += "  ИНВЕНТАРЬ \(Value(dictionary: loadInventoryCountByVnum).formatted(for: style, enumSpec: enumSpec))\n"

        }
        if !loadItemsOnDeathCountByVnum.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["посмертно"]
            result += "  ПОСМЕРТНО \(Value(dictionary: loadInventoryCountByVnum).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if let loadMoney = loadMoney {
            result += "  ДЕНЬГИ \(Value(dice: loadMoney).formatted(for: style))\n"
        }
        if let wimpLevel = wimpLevel {
            result += "  ТРУСОСТЬ \(Value(number: wimpLevel).formatted(for: style))\n"
        }
        // FIXME: ensure that it's set when insantiating mobile
        // maxMovement = 50
        if !procedures.isEmpty {
            result += "  ПРОЦЕДУРА \(Value(list: procedures).formatted(for: style))\n"
        }
        if let strength {
            result += "  СИЛА \(Value(number: strength).formatted(for: style))\n"
        }
        if let dexterity {
            result += "  ЛОВКОСТЬ \(Value(number: dexterity).formatted(for: style))\n"
        }
        if let constitution {
            result += "  ТЕЛОСЛОЖЕНИЕ \(Value(number: constitution).formatted(for: style))\n"
        }
        if let intelligence {
            result += "  РАЗУМ \(Value(number: intelligence).formatted(for: style))\n"
        }
        if let wisdom {
            result += "  МУДРОСТЬ \(Value(number: wisdom).formatted(for: style))\n"
        }
        // FIXME: charisma?
        // charisma = 13
        if let size = size {
            result += "  РАЗМЕР \(Value(number: size).formatted(for: style))\n"
        }
        if let health {
            result += "  ЗДОРОВЬЕ \(Value(number: health).formatted(for: style))\n"
        }
        if let weight = weight {
            result += "  ВЕС \(Value(number: weight).formatted(for: style))\n"
        }
        if let height = height {
            result += "  РОСТ \(Value(number: height).formatted(for: style))\n"
        }
        // FIXME: not implemented; unintuitive var name?
        if let weaponImmunityPercentage = weaponImmunityPercentage {
            result += "  ИММУНИТЕТ \(Value(number: weaponImmunityPercentage).formatted(for: style))\n"
        }
        if !skillKnowledgeLevels.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["умения"]
            result += "  УМЕНИЯ \(Value(dictionary: skillKnowledgeLevels).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if !spellsKnown.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["заклинания"]
            result += "  ЗАКЛИНАНИЯ \(Value(list: spellsKnown).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if !spellsToMemorize.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["заучивание"]
            let shortForm = spellsToMemorize.mapValues { $0 != 1 ? $0 : nil } // use short form
            result += "  ЗАУЧИВАНИЕ \(Value(dictionary: shortForm).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if !affects.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["мэффекты"]
            result += "  МЭФФЕКТЫ \(Value(list: affects).formatted(for: style, enumSpec: enumSpec))\n"
        }
        if !flags.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["мсвойства"]
            result += "  МСВОЙСТВА \(Value(flags: flags).formatted(for: style, enumSpec: enumSpec))\n"
        }

        for event in eventOverrides {
            result += structureIfNotEmpty("МПЕРЕХВАТ") { content in
                do {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["мперехват.событие"]
                    content += "    СОБЫТИЕ \(Value(enumeration: event.eventId).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if !event.actionFlags.isEmpty {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["мперехват.выполнение"]
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
        
        if let shopkeeper = shopkeeper {
            result += structureIfNotEmpty("МАГАЗИН") { content in
                if let sellProfit = shopkeeper.sellProfit {
                    content += "    ПРОДАЖА \(Value(number: sellProfit).formatted(for: style))\n"
                }
                if let buyProfit = shopkeeper.buyProfit {
                    content += "    ПОКУПКА \(Value(number: buyProfit).formatted(for: style))\n"
                }
                if let repairProfit = shopkeeper.repairProfit {
                    content += "    ПОЧИНКА \(Value(number: repairProfit).formatted(for: style))\n"
                }
                if let repairLevel = shopkeeper.repairLevel {
                    content += "    МАСТЕРСТВО \(Value(number: repairLevel).formatted(for: style))\n"
                }
                if !shopkeeper.producingItemVnums.isEmpty {
                    content += "    МЕНЮ \(Value(list: shopkeeper.producingItemVnums).formatted(for: style))\n"
                }
                if !shopkeeper.buyingItemsOfType.isEmpty {
                    let itemTypeFlagsRaw: UInt32 = shopkeeper.buyingItemsOfType.reduce(0) { result, itemType in
                        return result + (1 << (UInt32(itemType.rawValue) - 1))
                    }
                    let itemTypeFlags = ItemTypeFlagsDeprecated(rawValue: itemTypeFlagsRaw)
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["магазин.товар"]
                    content += "    ТОВАР \(Value(enumeration: itemTypeFlags).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if !shopkeeper.restrictFlags.isEmpty {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["магазин.запрет"]
                    content += "    ЗАПРЕТ \(Value(flags: shopkeeper.restrictFlags).formatted(for: style, enumSpec: enumSpec))\n"
                }
            }
        }

        if let stablemanNoteVnum = stablemanNoteVnum {
            result += "  КОНЮХ \(Value(number: stablemanNoteVnum).formatted(for: style))\n"
        }

        if let savingAcid = saves[.acid] {
            result += "  ЗКИСЛОТА \(Value(number: savingAcid).formatted(for: style))\n"
        }
        if let savingCold = saves[.cold] {
            result += "  ЗХОЛОД \(Value(number: savingCold).formatted(for: style))\n"
        }
        if let savingElectricity = saves[.electricity] {
            result += "  ЗЭЛЕКТРИЧЕСТВО \(Value(number: savingElectricity).formatted(for: style))\n"
        }
        if let savingCrush = saves[.crush] {
            result += "  ЗУДАР \(Value(number: savingCrush).formatted(for: style))\n"
        }
        if let savingHeat = saves[.heat] {
            result += "  ЗОГОНЬ \(Value(number: savingHeat).formatted(for: style))\n"
        }
        if let savingMagic = saves[.magic] {
            result += "  ЗМАГИЯ \(Value(number: savingMagic).formatted(for: style))\n"
        }

        for specialAttack in specialAttacks {
            result += structureIfNotEmpty("СПЕЦ") { content in
                do {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["спец.тип"]
                    content += "    ТИП \(Value(enumeration: specialAttack.type).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if specialAttack.frag != .magic {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["спец.разрушение"]
                    content += "    РАЗРУШЕНИЕ \(Value(enumeration: specialAttack.frag).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if let level = specialAttack.level {
                    content += "    УРОВЕНЬ \(Value(number: level).formatted(for: style))\n"
                }
                if !specialAttack.usageFlags.isEmpty {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["спец.применение"]
                    content += "    ПРИМЕНЕНИЕ \(Value(flags: specialAttack.usageFlags).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if !specialAttack.damage.isZero {
                    content += "    ВРЕД \(Value(dice: specialAttack.damage).formatted(for: style))\n"
                }
                if let spell = specialAttack.spell {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["спец.заклинание"]
                    content += "    ЗАКЛИНАНИЕ \(Value(enumeration: spell).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if let toFoes = specialAttack.toFoes {
                    content += "    ВРАГАМ \(Value(line: toFoes).formatted(for: style))\n"
                }
                if let toFriends = specialAttack.toFriends {
                    content += "    ДРУЗЬЯМ \(Value(line: toFriends).formatted(for: style))\n"
                }
                if let toVictim = specialAttack.toVictim {
                    content += "    ИГРОКУ \(Value(line: toVictim).formatted(for: style))\n"
                }
                if let toRoom = specialAttack.toRoom {
                    content += "    КОМНАТЕ \(Value(line: toRoom).formatted(for: style))\n"
                }
            }
        }
        
        if let corpseVnum = corpseVnum {
            result += "  НОМЕРТРУПА \(Value(number: corpseVnum).formatted(for: style))\n"
        }

        if let corpse = corpse {
            result += structureIfNotEmpty("ТРУП") { content in
                if let name = corpse.name {
                    content += "    ИМЯ \(Value(line: name).formatted(for: style))\n"
                }
                if let synonyms = corpse.synonyms {
                    content += "    СИНОНИМЫ \(Value(line: synonyms).formatted(for: style))\n"

                }
                if let groundDescription = corpse.groundDescription {
                    content += "    СТРОКА \(Value(line: groundDescription).formatted(for: style))\n"
                }
                if !corpse.description.isEmpty {
                    content += "    ОПИСАНИЕ \(Value(longText: description).formatted(for: style))\n"
                }
                if let gender = corpse.gender {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["труп.род"]
                    content += "    РОД \(Value(enumeration: gender).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if let material = corpse.material {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["труп.материал"]
                    content += "    МАТЕРИАЛ \(Value(enumeration: material).formatted(for: style, enumSpec: enumSpec))\n"
                }
            }
        }

        return result
    }
}

