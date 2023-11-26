import Foundation

class Creature {
    enum GainExperienceMode {
        case silent
        case normal
        case expend
    }
    
    var uid: UInt64 = 0
    var descriptors: Set<Descriptor> = []
    var isConnected: Bool { return !descriptors.isEmpty }
    
    var nameNominative: MultiwordName = MultiwordName("")
    var nameGenitive: MultiwordName = MultiwordName("")
    var nameDative: MultiwordName = MultiwordName("")
    var nameAccusative: MultiwordName = MultiwordName("")
    var nameInstrumental: MultiwordName = MultiwordName("")
    var namePrepositional: MultiwordName = MultiwordName("")
    func nameCompressed() -> String {
        let isAnimate = !(mobile?.prototype.flags.contains(.inanimate) ?? false)
        return endings.compress(
            names: [nameNominative.full, nameGenitive.full, nameDative.full, nameAccusative.full, nameInstrumental.full, namePrepositional.full],
            isAnimate: isAnimate
        )
    }
    
    func nameNominativeVisible(of whom: Creature) -> String {
        return canSee(whom) ? whom.nameNominative.full : "кто-то"
    }
    func nameGenitiveVisible(of whom: Creature) -> String {
        return canSee(whom) ? whom.nameGenitive.full : "кого-то"
    }
    func nameDativeVisible(of whom: Creature) -> String {
        return canSee(whom) ? whom.nameDative.full : "кому-то"
    }
    func nameAccusativeVisible(of whom: Creature) -> String {
        return canSee(whom) ? whom.nameAccusative.full : "кого-то"
    }
    func nameInstrumentalVisible(of whom: Creature) -> String {
        return canSee(whom) ? whom.nameInstrumental.full : "кем-то"
    }
    func namePrepositionalVisible(of whom: Creature) -> String {
        return canSee(whom) ? whom.namePrepositional.full : "ком-то"
    }
    
    var description: [String] = [] // Detailed description

    var idleTics = 0 // Tics idle in game
    var laggedTillGamePulse: UInt64 = 0 // Lag till what game pulse

    var player: Player? // PC-only data
    var mobile: Mobile? // MOB-only data

    var isPlayer: Bool { return player != nil }
    var isMobile: Bool { return mobile != nil }
    
    var controllingPlayer: Player? { return player }
    
    // If it's a player, his flags
    // If it's a mobile, flags of it's controlling player (if any)
    var preferenceFlags: PlayerPreferenceFlags? {
        get { return controllingPlayer?.preferenceFlags }
        set {
            controllingPlayer?.preferenceFlags = newValue ?? []
        }
    }
    
    var pageWidth: Int16 {
        get { return controllingPlayer?.pageWidth ?? defaultPageWidth }
        set { controllingPlayer?.pageWidth = newValue }
    }
    
    var pageLength: Int16 {
        get { return controllingPlayer?.pageLength ?? defaultPageLength }
        set { controllingPlayer?.pageLength = newValue }
    }
    
    var gender: Gender = .neuter
    func genderVisible(of target: Creature) -> Gender {
        return canSee(target) ? target.gender : .masculine
    }

    var classId: ClassId = .amalgamated // FIXME: introduce 'none'
    var race: Race = .human
    var level: UInt8 = 0 // Level
    // FIXME: move these functions to extensino
    func adjustLevel() {
        guard isPlayer else { return }
        
        while level <= maximumMortalLevel && experience >= classId.info.experience(forLevel: level + 1) {
            advanceLevel()
            act("&1Вы получили уровень!&2", .toSleeping, .to(self), .text(bWht()), .text(nNrm()))
        }
        while level > 1 && experience < classId.info.experience(forLevel: level) - levelLossBuffer() {
            loseLevel()
            act("&1Вы потеряли уровень!&2", .toSleeping, .to(self), .text(bWht()), .text(nNrm()))
        }
    }
    
    private func advanceLevel() {
        guard let player = player else { return }
        
        if level >= 1 && level <= maximumMortalLevel {
            if let gain = player.hitPointGains[validating: Int(level)] {
                realMaximumHitPoints += Int(gain)
            } else {
                while player.hitPointGains.count < level {
                    fatalError("Player missed some gains before level \(level)")
                    //assertionFailure()
                    //player.hitPointGains.append(0)
                }
                let gain = classId.info.hitPointGain.roll()
                player.hitPointGains.append(UInt8(gain))
                realMaximumHitPoints += gain
            }
        }

        level += 1
        
        log("\(nameNominative) advances to level \(level)")
        logToMud("\(nameNominative) получает уровень \(level).", verbosity: .brief)

        if level == 3 && !player.flags.contains(.rolled) {
            rollRealAbilities()
            player.flags.insert(.rolled)
            log("New statistics: strength \(realStrength), dexterity \(realDexterity), constitution \(realConstitution), intelligence: \(realIntelligence), wisdom: \(realWisdom), charisma: \(realCharisma)")
            logToMud("Статистики: сила \(realStrength), ловкость \(realDexterity), телосложение (\(realConstitution), разум: \(realIntelligence), мудрость: \(realWisdom), обаяние: \(realCharisma)", verbosity: .brief)
        }
        
        //save_char_safe(ch, RENT_CRASH);
        player.scheduleForSaving()
        players.save()
    }
    
    private func levelLossBuffer() -> Int {
        return (classId.info.experience(forLevel: level) -
            classId.info.experience(forLevel: level - 1)) / 10
    }
    
    private func loseLevel() {
        guard let player = player else { return }

        let hitpointsLoss: Int
        if let loss = player.hitPointGains[validating: Int(level - 1)] {
            hitpointsLoss = Int(loss)
        } else {
            hitpointsLoss = classId.info.maxHitPerLevel
            log("\(nameNominative) hasn't got hitpoint gains logged")
            logToMud("У персонажа \(nameNominative) не запомнены значения жизни для уровней", verbosity: .brief)
        }
        
        // FIXME
        //for (circle = max_circle(ch); circle >= 1; --circle)
        //for (slot = CH_SLOT_AVAIL(ch, circle) + 1; slot <= 18; ++slot) {
        //    CH_SLOT(ch, circle, slot) = 0;
        //    REMOVE_BIT_AR(CH_SLOTSTATE(ch), 18 * (circle - 1) + slot);
        //}
        
        realMaximumHitPoints -= hitpointsLoss
        if realMaximumHitPoints < 1 {
            realMaximumHitPoints = 1
        }
        let affectedHitPoints = affectedMaximumHitPoints()
        if hitPoints > affectedHitPoints {
            hitPoints = affectedHitPoints
        }
        
        log("\(nameNominative) descends to level \(level)")
        logToMud("Персонаж \(nameNominative) спускается на уровень \(level).", verbosity: .brief)
        
        //save_char_safe(ch, RENT_CRASH);
        player.scheduleForSaving()
        players.save()
    }
    
    var realAlignment: Alignment = 0 // Alignment
    func affectedAlignment() -> Alignment {
        return Alignment(clamping: affected(baseValue: realAlignment.value, by: .custom(.alignment)))
    }
    var realSize: UInt8 = 30
    func affectedSize() -> Int {
        return affected(
            baseValue: Int(realSize),
            by: .custom(.size),
            clampedTo: 1...250
        )
    }
    func defaultWeight(forSize size: UInt8) -> UInt {
        return UInt(size) * 5
    }
    var weight: UInt = 0
    var height: UInt = 198
    
    // Abilities
    var realStrength: UInt8 = 0
    func affectedStrength() -> Int {
        return affected(
            baseValue: Int(realStrength) + ageModifier(for: .custom(.strength)),
            by: .custom(.strength),
            clampedTo: 3...(isMobile ? 36 : 28))
    }
    var realDexterity: UInt8 = 0
    func affectedDexterity() -> Int {
        return affected(
            baseValue: Int(realDexterity) + ageModifier(for: .custom(.dexterity)),
            by: .custom(.dexterity),
            clampedTo: 3...(isMobile ? 36 : 28))
    }
    var realConstitution: UInt8 = 0
    func affectedConstitution() -> Int {
        return affected(
            baseValue: Int(realConstitution) + ageModifier(for: .custom(.constitution)),
            by: .custom(.constitution),
            clampedTo: 3...(isMobile ? 36 : 28))
    }
    var realIntelligence: UInt8 = 0
    func affectedIntelligence() -> Int {
        return affected(
            baseValue: Int(realIntelligence) + ageModifier(for: .custom(.intelligence)),
            by: .custom(.intelligence),
            clampedTo: 3...(isMobile ? 36 : 28))
    }
    var realWisdom: UInt8 = 0
    func affectedWisdom() -> Int {
        return affected(
            baseValue: Int(realWisdom) + ageModifier(for: .custom(.wisdom)),
            by: .custom(.wisdom),
            clampedTo: 3...(isMobile ? 36 : 28))
    }
    var realCharisma: UInt8 = 13
    func affectedCharisma() -> Int {
        return affected(
            baseValue: Int(realCharisma) + ageModifier(for: .custom(.charisma)),
            by: .custom(.charisma),
            clampedTo: 3...(isMobile ? 36 : 28))
    }
    var realHealth: UInt8 = 100
    func affectedHealth() -> Int {
        return affected(baseValue: Int(realHealth), by: .custom(.health))
    }
    
    // Attack, defense and dam absorbtion
    var realAttack = 0
    func affectedAttack() -> Int {
        return affected(baseValue: realAttack, by: .custom(.attack))
    }
    var realDefense = 0
    func affectedDefense() -> Int {
        return affected(baseValue: realDefense, by: .custom(.defense))
    }
    var realAbsorb = 0
    func affectedAbsorb() -> Int {
        return affected(baseValue: realAbsorb, by: .custom(.absorb))
    }
    // FIXME: make this separate damroll, use full attack1 dice for mobiles
    var realDamroll: Int8 = 0 // Any bonus or penalty to dam in hits
    func affectedDamroll() -> Int {
        return affected(baseValue: Int(realDamroll), by: .custom(.damroll))
    }
    
    var realSaves: [Frag: Int16] = [:]
    func affectedSave(_ frag: Frag) -> Int {
        var save = Int(realSaves[frag] ?? 0)
        save += affected(baseValue: 0, by: .save(frag: frag))
        save += affected(baseValue: 0, by: .custom(.savingAll))
        //TODO сделать ещё отдельную обработку поглощения для SAVING_CRUSH
        switch race {
        case .dwarf:
            save += frag == .heat ? 30 : 20
        case .highElf, .wildElf:
            save += frag == .electricity ? 20 : 10
        case .construct:
            switch frag {
            case .heat: save += 40
            case .crush: save += 20
            case .magic: save += 10
            default: break
            }
        case .dragon:
            save += 40
        case .goblin:
            save += frag == .acid ? 15 : -10
        case .undead:
            if frag == .cold {
                save += 50
            }
        default:
            break
        }
        
        // special holy bonus for solamnic kights
        if classId == .solamnic {
            let alig = affectedAlignment()
            if alig.value > 700 {
                let k1 = 1 + Int(level) / 6
                let k2 = alig.value - 700
                save += k1 * k2 / 75
            }
        }

        return save
    }
    
    // Hit points
    var hitPoints: Int = 1
    var realMaximumHitPoints: Int = 0
    func affectedMaximumHitPoints() -> Int {
        var hitPoints = affected(baseValue: realMaximumHitPoints, by: .custom(.hitPoints))
        
        if isPlayer {
            let maxHitPerLevel = classId.info.maxHitPerLevel
            let k1 = 5 * maxHitPerLevel / 2 + 15
            let constitutionModifier = Int(realConstitution) - 13
            hitPoints += (k1 * Int(level) * constitutionModifier) / 100
        }

        return hitPoints.clamped(to: 1...1000000)
    }
    func hitPointsPercentage() -> Int {
        return (100 * hitPoints) / affectedMaximumHitPoints();
    }

    // Movement points
    var arrivedAtGamePulse: UInt64 = 0
    var movement = 0
    var realMaximumMovement = 50
    func affectedMaximumMovement() -> Int {
        return affected(baseValue: realMaximumMovement, by: .custom(.movement), clampedTo: 1...1000000)
    }
    var movementPathInitialRoom: Int?
    var movementPath: [MovementPathEntry] = []
    
    var gold = 0 // Coins
    var experience = 0 // Don't assign directly, use gainExperience() to apply game rules

    func gainExperience(_ gain: Int, mode: GainExperienceMode) {
        guard isPlayer else { return }
        guard level <= maximumMortalLevel else { return }

        // Wiscom affects experience gain: 28 - 130%, 8 - 90%
        var gain = ((100 + (affectedWisdom() - 13) * 2) * gain) / 100

        if gain > 0 {
            let isTraining = preferenceFlags?.contains(.training) ?? false
            guard !isTraining else { return }
            gain = min((classId.info.experience(forLevel: level + 1) -
                classId.info.experience(forLevel: level)) / (level > 5 ? 25 : 20 + Int(level)),
                       min(500000, gain))
            
            experience += gain
            if mode != .silent {
                act("Вы получили # очк#(о,а,ов) опыта.", .toSleeping, .to(self), .number(gain))
            }
            adjustLevel()
        } else if gain < 0 {
            //XXX а не ограничить ли макс.потерю опыть не 10млн, а, скажем, 5?
            gain = max(-experience, max(-10000000, gain))
            // Don't lose more than 1 level
            gain = max(-(classId.info.experience(forLevel: level) - classId.info.experience(forLevel: level - 1)), gain)
            experience += gain
            
            let message: String
            switch mode {
            case .normal:
                message = "Вы потеряли # очк#(о,а,ов) опыта!"
            case .expend:
                message = "Вы потратили # очк#(о,а,ов) опыта."
            default:
                message = ""
            }
            if !message.isEmpty {
                act(message, .toSleeping, .to(self), .number(-gain))
            }
            adjustLevel()
        } else {
            send("Вы не получили никакого опыта.")
        }
    }
    var realWimpLevel: UInt8 = 0 // Flee if below this % of hit points
    func affectedWimpLevel() -> Int {
        return affected(
            baseValue: Int(realWimpLevel),
            by: .custom(.wimpyLevel),
            clampedTo: 0...100
        )
    }
    
    // skillNum: knowledgeLevel
    var skillKnowledgeLevels: [Skill: UInt8] = [:]
    var spellsKnown: Set<Spell> = []
    
    // Spell circle: slots
    var spellsMemorized: [Spell: UInt8] = [:]
    var spellsBeingMemorized: [Spell: UInt8] = [:]
    var memorizationTimeLeft: Double = 0 // global memorization time
    
    var affects: [Affect] = []
    var skillLag: [Skill: UInt8] = [:]
    
    // Drunk, thirst, hunger
    var drunk: Int8? // nil if can't become drunk
    // FIXME: why they're inverted?
    var thirst: Int8? // nil if disabled
    var hunger: Int8? // nil if disabled
    
    var position: Position = .standing // Standing, fighting, sleeping, etc.
    var isAwake: Bool { return position.isAwake }
    var skipRounds: UInt8 = 0 // How many combat rounds to skip?
    var bandage: Int8 = 0 // Percentage bonus to hit gain
    var berserkRounds: UInt8 = 0 // Be berserk for this time
    
    var runtimeFlags: CreatureRuntimeFlags = []
    
    var bonus: UInt = 0 // For hit regen
    var mvbonus: UInt = 0 // For movement regen
    
    var inRoom: Room?
    
    var following: Creature?
    var isFollowing: Bool { return following != nil }
    var followers: [Creature] = []
    
    var fighting: Creature? // Opponent
    var isFighting: Bool { return fighting != nil }
    var riding: Creature? // Whom am I riding?
    var isRiding: Bool { return riding != nil }
    var riddenBy: Creature? // Who is riding me?
    var isRiddenBy: Bool { return riddenBy != nil }
    
    var carrying: [Item] = []
    var equipment: [EquipmentPosition: Item] = [:]
    
    init(uid: UInt64?, db: Db) {
        self.uid = uid ?? db.createCreatureUid()
        
        db.creaturesByUid[self.uid] = self
    }
    
    init(from playerFile: ConfigFile, db: Db) {
        let s = "ОСНОВНАЯ"
        
        player = Player(from: playerFile, nameNominative: nameNominative.full, creature: self)
        player?.nameCombined = playerFile[s, "ИМЯ"] ?? "" // also inits nameNominative

        // Если у игрока нет UID-а, присвоить ему новый... Если есть - использовать его собственный:
        uid = playerFile[s, "УИД"] ?? db.createCreatureUid()
        
        description = (playerFile[s, "ОПИСАНИЕ"] ?? "").components(separatedBy: .newlines)
        
        /* FIXME
        do {
            let affectsCount: Int = playerFile[s, "ВЛИЯНИЙ"] ?? 0
            for i in 0 ..< affectsCount {
                guard let typeId: UInt16 = playerFile[s, "ВЛИЯНИЕ[\(i)].ТИП"] else { continue }
                guard let type = Affect.AffectType(id: typeId) else {
                        logError("Player \(nameNominative): ignoring unknown affect type \(typeId)")
                        continue
                }
                let affect = Affect(type: type)
                affect.level = playerFile[s, "ВЛИЯНИЕ[\(i)].УРОВЕНЬ"] ?? 0
                affect.duration = playerFile[s, "ВЛИЯНИЕ[\(i)].ДЛИТЕЛЬНОСТЬ"] ?? 0
                affect.decrement = Affect.DurationDecrementMode(rawValue:  playerFile[s, "ВЛИЯНИЕ[\(i)].БОЕВОЙ"] ?? 0) ?? .everyMinute
                affect.apply = Apply(id: playerFile[s, "ВЛИЯНИЕ[\(i)].ЗНАЧЕНИЕ"] ?? 0) ?? .none
                affect.modifier = playerFile[s, "ВЛИЯНИЕ[\(i)].МОДИФИКАТОР"] ?? 0

                affected.append(affect)
            }
        }
         */
        
        do {
            let skillLagCount: Int = playerFile[s, "ЗАДЕРЖЕК"] ?? 0
            for i in 0 ..< skillLagCount {
                guard let typeId: UInt16 = playerFile[s, "ЗАДЕРЖКА[\(i)].ТИП"] else { continue }
                guard let type = Skill(rawValue: typeId) else {
                    logError("Player \(nameNominative): ignoring unknown skill lag type \(typeId)")
                    continue
                }
                guard let lag: UInt8 = playerFile[s, "ЗАДЕРЖКА[\(i)].ВЕЛИЧИНА"] else {
                    log("Player \(nameNominative): ignoring zero skill lag")
                    continue
                }
                skillLag[type] = lag
            }
        }
        
        realSize = playerFile[s, "РАЗМЕР"] ?? realSize
        weight = playerFile[s, "ВЕС"] ?? defaultWeight(forSize: realSize)
        height = playerFile[s, "РОСТ"] ?? height
        
        gender = Gender(rawValue: playerFile[s, "ПОЛ"] ?? Gender.masculine.rawValue) ?? .masculine
        classId = ClassId(rawValue: playerFile[s, "ПРОФЕССИЯ"] ?? ClassId.amalgamated.rawValue) ?? .amalgamated // FIXME: introduce 'none'
        race = Race(rawValue: playerFile[s, "РАСА"] ?? 0) ?? .human
        level = playerFile[s, "УРОВЕНЬ"] ?? 0
        
        realStrength = playerFile[s, "СИЛ"] ?? 0
        realDexterity = playerFile[s, "ЛОВ"] ?? 0
        realConstitution = playerFile[s, "ТЕЛ"] ?? 0
        realIntelligence = playerFile[s, "ИНТ"] ?? 0
        realWisdom = playerFile[s, "МУД"] ?? 0
        realCharisma = playerFile[s, "ОБА"] ?? 0
        
        realHealth = playerFile[s, "ЗДОРОВЬЕ"] ?? 0
        realDamroll = playerFile[s, "ВРЕД"] ?? 0
        
        realSaves[.magic] = playerFile[s, "ЗМАГИЯ"] ?? 0
        realSaves[.heat] = playerFile[s, "ЗОГОНЬ"] ?? 0
        realSaves[.cold] = playerFile[s, "ЗХОЛОД"] ?? 0
        realSaves[.acid] = playerFile[s, "ЗКИСЛОТА"] ?? 0
        realSaves[.electricity] = playerFile[s, "ЗЭЛЕКТРИЧЕСТВО"] ?? 0
        realSaves[.crush] = playerFile[s, "ЗУДАР"] ?? 0

        hitPoints = playerFile[s, "ТЕКЖИЗНЬ"] ?? 0
        realMaximumHitPoints = playerFile[s, "ЖИЗНЬ"] ?? 0
        movement = playerFile[s, "ТЕКБОДРОСТЬ"] ?? 0
        realMaximumMovement = playerFile[s, "БОДРОСТЬ"] ?? 0
        movement = min(movement, realMaximumMovement)
        
        realAttack = playerFile[s, "АТАКА"] ?? 0
        realDefense = playerFile[s, "ЗАЩИТА"] ?? 0
        realAbsorb = playerFile[s, "ПОГЛОЩЕНИЕ"] ?? 0

        gold = playerFile[s, "ДЕНЬГИ"] ?? 0
        experience = playerFile[s, "ОПЫТ"] ?? 0
        
        realAlignment = Alignment(clamping: playerFile[s, "НАКЛОННОСТИ"] ?? 0)
        bandage = playerFile[s, "ПЕРЕВЯЗКА"] ?? 0

        do {
            let skillCount: Int = playerFile[s, "УМЕНИЙ"] ?? 0
            for i in 0 ..< skillCount {
                // Contrary to it's name can be a skill as well as a spell
                let typeId: UInt16 = playerFile[s, "УМЕНИЕ[\(i)].НОМ"] ?? 0
                let knowledgeLevel: UInt8 = playerFile[s, "УМЕНИЕ[\(i)].ЗН"] ?? 0
                if let skill = Skill(rawValue: typeId) {
                    skillKnowledgeLevels[skill] = knowledgeLevel
                } else if let spell = Spell(rawValue: typeId) {
                    spellsKnown.insert(spell)
                } else {
                    logWarning("Player \(nameNominative): ignoring unknown skill or spell \(typeId)")
                    continue
                }
            }
        }

//        do {
//            let memorization: String = playerFile[s, "ЗАП.МАССИВ.ЗАКЛИНАНИЯ"] ?? ""
//            let spellIds: [UInt16?] = memorization.components(separatedBy: ",")
//                .map { $0.trimmingCharacters(in: .whitespaces) }
//                .map {
//                    // Turn '0' spells into empty slots
//                    guard let spellId = UInt16($0), spellId != 0 else { return nil }
//                    return spellId
//                }
//
//            let slotFlagsString: String = playerFile[s, "ЗАП.МАССИВ.СЛОТЫ"] ?? ""
//            let slotFlagsArray: [UInt32] = slotFlagsString.components(separatedBy: ",")
//                .map { $0.trimmingCharacters(in: .whitespaces) }
//                .map { UInt32($0) ?? 0 }
//            let slotFlags = BitArray(rawValue: slotFlagsArray)
//
//            // 9 circles, 18 spells max each
//            for (index, spellIdOrNil) in spellIds.enumerated() {
//                guard let spellId = spellIdOrNil else { continue } // skip empty slots
//                let circle: UInt8 = UInt8(1 + (index / 18))
//                guard let spell = Spell(rawValue: spellId) else {
//                    logError("Player \(nameNominative): ignoring slot with unknown spell \(spellId)")
//                    continue
//                }
//                let isMemorized = slotFlags.isSet(bitIndex: index)
//                let slot = Slot(spell: spell, isMemorized: isMemorized)
//                var slots = getSlotsForCircle(circle)
//                slots.append(slot)
//                slotsForCircle[circle] = slots
//            }
//        }
        
        memorizationTimeLeft = playerFile[s, "ЗАП.ВРЕМЯ"] ?? 0
        
        realWimpLevel = playerFile[s, "ТРУСОСТЬ"] ?? 0
        let hunger: Int8 = playerFile[s, "ГОЛОД"] ?? 0
        self.hunger = hunger != -1 ? hunger : nil
        let thirst: Int8 = playerFile[s, "ЖАЖДА"] ?? 0
        self.thirst = thirst != -1 ? thirst : nil
        let drunk: Int8 = playerFile[s, "ОПЬЯНЕНИЕ"] ?? 0
        self.drunk = drunk != -1 ? drunk : nil
        
        db.creaturesByUid[self.uid] = self
    }
    
    init(prototype: MobilePrototype, uid: UInt64?, db: Db, room: Room) {
        self.uid = uid ?? db.createCreatureUid()

        let mobile = Mobile(prototype: prototype, creature: self)
        
        nameNominative = MultiwordName(prototype.nameNominative)
        nameGenitive = MultiwordName(prototype.nameGenitive)
        nameDative = MultiwordName(prototype.nameDative)
        nameAccusative = MultiwordName(prototype.nameAccusative)
        nameInstrumental = MultiwordName(prototype.nameInstrumental)
        namePrepositional = MultiwordName(prototype.namePrepositional)
        description = prototype.description

        self.mobile = mobile

        gender = prototype.gender
        classId = prototype.classId
        race = prototype.race
        level = prototype.level
        realAlignment = prototype.alignment
        realSize = prototype.size ?? realSize
        weight = prototype.weight ?? defaultWeight(forSize: realSize)
        height = prototype.height ?? height

        realStrength = prototype.strength ?? realStrength
        realDexterity = prototype.dexterity ?? realDexterity
        realConstitution = prototype.constitution ?? realConstitution
        realIntelligence = prototype.intelligence ?? realIntelligence
        realWisdom = prototype.wisdom ?? realWisdom
        realCharisma = prototype.charisma ?? realCharisma
        
        realHealth = prototype.health ?? realHealth
        
        realSaves = prototype.saves
        
        realAttack = prototype.attack
        realDefense = prototype.defense
        realAbsorb = prototype.absorb ?? realAbsorb
        
        realMaximumHitPoints = prototype.maximumHitPoints

        experience = prototype.experience // FIXME: calculate automatically
        realWimpLevel = prototype.wimpLevel ?? realWimpLevel
        
        skillKnowledgeLevels = prototype.skillKnowledgeLevels.mapValues { $0 ?? tableB(level) }
        spellsKnown = prototype.spellsKnown
        
        spellsMemorized = prototype.spellsToMemorize

        position = mobile.defaultPosition

        //        //{"команда",        vtSTRING, 0, &prs_mob_mob.zcmd_force, NO_SPEC}
//
//            /*
//        {Proc,             vtLONG,   vaLIST, (void*)prs_w_trig, NO_SPEC},
//         */
//
//        // Other

//        position = prototype["положение"]?.uint8.flatMap { Position(rawValue: $0) } ?? .standing
//        
//        // FIXME
//        //{"иммунитет",      vtNONE,   0,         NULL, NO_SPEC},
//        
//        // FIXME
//        // {"мэффекты",       vtWORD,   vaLIST,    (void*)prs_w_maffects, NO_SPEC},
//        
//        // Attack
//        if let dice = prototype["вред1"]?.dice {
//            if let damroll = Int8(exactly: dice.add) {
//                self.damroll = damroll
//            } else {
//                logError("Mobile.init(): 'вред1' values out of range")
//            }
//        }
//        
//        /*
//        /* Перехват */
//        {Ovr_cmd,    vtSHORT,  vaPRIME, &prs_ovr.opcode,         SPC_OVR},
//        {Ovr_player, vtSTRING, 0,       &prs_ovr.msg_to_char,    SPC_OVR},
//        {Ovr_victim, vtSTRING, 0,       &prs_ovr.msg_to_vict,    SPC_OVR},
//        {Ovr_others, vtSTRING, 0,       &prs_ovr.msg_to_notvict, SPC_OVR},
//        {Ovr_room,   vtSTRING, 0,       &prs_ovr.msg_to_room,    SPC_OVR},
//        /* Триггеры
//         {"триггер.событие", vtSTRING, vaPRIME, &prs_trig.event, SPC_TRIG},
//         {"триггер.функция", vtSTRING, 0, &prs_trig.func, SPC_TRIG}, */
//        /* Магазины */
//        {"магазин.продажа",    vtLONG,  vaPRIME, &prs_shp.sell_profit, SPC_SHOP},
//        {"магазин.покупка",    vtLONG,  0,       &prs_shp.buy_profit, SPC_SHOP},
//        {"магазин.починка",    vtLONG,  0,       &prs_shp.repair_profit, SPC_SHOP},
//        {"магазин.мастерство", vtLONG,  0,       &prs_shp.repair_lev, SPC_SHOP}, // fixme? wtf
//        {"магазин.меню",       vtDWORD, vaLIST,  (void*)prs_w_shop_producing, SPC_SHOP},
//        {"магазин.товар",      vtLONG,  0,       &prs_shp.type, SPC_SHOP},
//        {"магазин.признаки",   vtLONG,  0,       &prs_shp.info, SPC_SHOP},
//        {"магазин.запрет",     vtLONG,  0,       &prs_shp.restrict, SPC_SHOP},
//        {"конюх", vtDWORD, 0, &prs_mob_mob.stableman, NO_SPEC},
//        // TODO: МАГАЗИН.РАЗРЕШЕНИЕ  Б   ;Обслуживаемые покупатели
//        //  {"магазин.уровень", vtLONG, 0, &prs_shp.repair_lev, SPC_SHOP}, // fixme? wtf
//        /* Защищенность моба от магии - пока не реализовано :-( */
//        {"зкислота",       vtSHORT, 0, &prs_mob_mob.saves[SAVING_ACID], NO_SPEC},
//        {"зхолод",         vtSHORT, 0, &prs_mob_mob.saves[SAVING_COLD], NO_SPEC},
//        {"зэлектричество", vtSHORT, 0, &prs_mob_mob.saves[SAVING_ELEC], NO_SPEC},
//        {"зудар",          vtSHORT, 0, &prs_mob_mob.saves[SAVING_CRUSH], NO_SPEC},
//        {"зогонь",         vtSHORT, 0, &prs_mob_mob.saves[SAVING_HEAT], NO_SPEC},
//        {"змагия",         vtSHORT, 0, &prs_mob_mob.saves[SAVING_MAGIC], NO_SPEC},
//        /* Спец атаки */
//        {"спец.тип",        vtBYTE,   vaPRIME, &prs_spec_attack.type,       SPC_SPEC_ATTACK},
//        {"спец.применение", vtBYTE,   0,       &prs_spec_attack.usage,      SPC_SPEC_ATTACK},
//        {"спец.разрушение", vtBYTE,   0,       &prs_spec_attack.frag_type,  SPC_SPEC_ATTACK},
//        {"спец.уровень",    vtBYTE,   0,       &prs_spec_attack.uselevel,   SPC_SPEC_ATTACK},
//        {"спец.вред",       vtLONG,   vaLIST,  (void*)prs_w_spec_dam,       SPC_SPEC_ATTACK},
//        {"спец.заклинание", vtLONG,   0,       &prs_spec_attack.spellnum,   SPC_SPEC_ATTACK},
//        {"спец.врагам",     vtSTRING, 0,       &prs_spec_attack.to_foes,    SPC_SPEC_ATTACK},
//        {"спец.друзьям",    vtSTRING, 0,       &prs_spec_attack.to_friends, SPC_SPEC_ATTACK},
//        {"спец.игроку",     vtSTRING, 0,       &prs_spec_attack.to_char,    SPC_SPEC_ATTACK},
//        {"спец.комнате",    vtSTRING, 0,       &prs_spec_attack.to_room,    SPC_SPEC_ATTACK},
//        // TODO: А может стоило сделать "СПЕЦ.ВСЕМ" ?
//        /* От монстра остаётся нестандартный труп */
//        {"номертрупа",     vtDWORD,  0, &prs_mob_mob.corpse_vn, NO_SPEC},
//        {"труп.имя",       vtSTRING, vaPRIME, &prs_corpse.name,         SPC_CORPSE},
//        {"труп.синонимы",  vtSTRING, 0,       &prs_corpse.syns,         SPC_CORPSE},
//        {"труп.строка",    vtSTRING, 0,       &prs_corpse.ground_descr, SPC_CORPSE},
//        {"труп.описание",  vtTEXT,   0,       &prs_corpse.description,  SPC_CORPSE},
//        {"труп.род",       vtBYTE,   0,       &prs_corpse.gender,       SPC_CORPSE},
//        {"труп.материал",  vtBYTE,   0,       &prs_corpse.material,     SPC_CORPSE}
//        
//        
//        chars_in_game.insert(make_pair(ch->uid, ch));
//        
//        CH_GOLD(ch) = dice(ch->mob->load_gold[0], ch->mob->load_gold[1]) + ch->mob->load_gold[2];
// // Restore them later after equipping mobile with +hp +mv items
//        ch->hit = ch->max_hit;
//        ch->move = ch->max_move;
//
//        mobs_index[ch->mob->vn].number++;
//        CH_ID(ch) = max_id++;
//        assign_triggers(ch, MOB_TRIGGER);
//        
//        /* Set innate affections: */
//        affbit_update(ch, ch, true);
//        */
        
        put(in: room)
        mobile.equip()
        hitPoints = affectedMaximumHitPoints()
        movement = affectedMaximumMovement()
        
        db.creaturesByUid[self.uid] = self
    }
    
    func save(to configFile: ConfigFile) {
        player?.save(to: configFile)
        
        guard let nameCombined = player?.nameCombined else { fatalError() }
        
        let s = "ОСНОВНАЯ"
        configFile[s, "УИД"] = uid
        configFile[s, "ИМЯ"] = nameCombined
        configFile[s, "ОПИСАНИЕ"] = description.joined(separator: "\n")

        configFile[s, "ЗАДЕРЖЕК"] = skillLag.count
        for (index, element) in skillLag.enumerated() {
            configFile[s, "ЗАДЕРЖКА[\(index)].ТИП"] = element.key.rawValue
            configFile[s, "ЗАДЕРЖКА[\(index)].ВЕЛИЧИНА"] = element.value
        }

        configFile[s, "РАЗМЕР"] = realSize
        configFile[s, "ВЕС"] = weight
        configFile[s, "РОСТ"] = height

        configFile[s, "ПОЛ"] = gender.rawValue
        configFile[s, "ПРОФЕССИЯ"] = classId.rawValue
        configFile[s, "РАСА"] = race.rawValue
        configFile[s, "УРОВЕНЬ"] = level

        configFile[s, "СИЛ"] = realStrength
        configFile[s, "ИНТ"] = realIntelligence
        configFile[s, "МУД"] = realWisdom
        configFile[s, "ЛОВ"] = realDexterity
        configFile[s, "ТЕЛ"] = realConstitution
        configFile[s, "ОБА"] = realCharisma

        configFile[s, "ЗДОРОВЬЕ"] = realHealth
        configFile[s, "ВРЕД"] = realDamroll
        
        configFile[s, "ЗМАГИЯ"] = realSaves[.magic]
        configFile[s, "ЗОГОНЬ"] = realSaves[.heat]
        configFile[s, "ЗХОЛОД"] = realSaves[.cold]
        configFile[s, "ЗКИСЛОТА"] = realSaves[.acid]
        configFile[s, "ЗЭЛЕКТРИЧЕСТВО"] = realSaves[.electricity]
        configFile[s, "ЗУДАР"] = realSaves[.crush]

        configFile[s, "ТЕКЖИЗНЬ"] = hitPoints
        configFile[s, "ЖИЗНЬ"] = realMaximumHitPoints
        configFile[s, "ТЕКБОДРОСТЬ"] = movement
        configFile[s, "БОДРОСТЬ"] = realMaximumMovement

        configFile[s, "АТАКА"] = realAttack
        configFile[s, "ЗАЩИТА"] = realDefense
        configFile[s, "ПОГЛОЩЕНИЕ"] = realAbsorb
        
        configFile[s, "ДЕНЬГИ"] = gold
        configFile[s, "ОПЫТ"] = experience
        
        configFile[s, "НАКЛОННОСТИ"] = realAlignment.value
        configFile[s, "ПЕРЕВЯЗКА"] = bandage

        configFile[s, "УМЕНИЙ"] = skillKnowledgeLevels.count + spellsKnown.count
        for (index, element) in skillKnowledgeLevels.enumerated() {
            configFile[s, "УМЕНИЕ[\(index)].НОМ"] = element.key.rawValue
            configFile[s, "УМЕНИЕ[\(index)].ЗН"] = element.value
        }
        for (offset, spell) in spellsKnown.enumerated() {
            let index = skillKnowledgeLevels.count + offset
            configFile[s, "УМЕНИЕ[\(index)].НОМ"] = spell.rawValue
            configFile[s, "УМЕНИЕ[\(index)].ЗН"] = 1
        }

// FIXME
//        do {
//            let slotFlagsArray: [UInt32] = Array(repeating: 0, count: 6)
//            let slotFlags = BitArray(rawValue: slotFlagsArray)
//            var out = ""
//            for circleIndex: UInt8 in 0 ..< 9 {
//                for slotIndex in 0 ..< 18 {
//                    if circleIndex != 0 || slotIndex != 0 {
//                        out += ", "
//                    }
//                    let slots = slotsForCircle[circleIndex]
//                    let slot = slots?[validating: slotIndex]
//                    let spellRawValue = slot?.spell.rawValue ?? 0
//                    if slot?.isMemorized ?? false {
//                        slotFlags.set(bitIndex: Int(circleIndex) * 18 + Int(slotIndex))
//                    }
//                    out += String(spellRawValue)
//                }
//            }
//            configFile[s, "ЗАП.МАССИВ.ЗАКЛИНАНИЯ"] = out
//            configFile[s, "ЗАП.МАССИВ.СЛОТЫ"] = slotFlags.rawValue.map({ String($0) }).joined(separator: ", ")
//        }
        
        configFile[s, "ЗАП.ВРЕМЯ"] = memorizationTimeLeft

        configFile[s, "ТРУСОСТЬ"] = realWimpLevel
        configFile[s, "ГОЛОД"] = hunger ?? -1
        configFile[s, "ЖАЖДА"] = thirst ?? -1
        configFile[s, "ОПЬЯНЕНИЕ"] = drunk ?? -1

    }
    
    // Bring char alive and ready before (re)entering the game
    func reset() {
        runtimeFlags = []
        position = .standing
        
        hitPoints = max(1, hitPoints)
        movement = max(0, movement)
        bonus = 0
        mvbonus = 0
        skipRounds = 0
        
        if let player = player {
            player.trackRdir = 0
            player.trackDblCrs = 0
            player.lastTell = nil
            player.lastIp.removeAll()
            player.lastHostname.removeAll()
            player.incomingTells.removeAll(keepingCapacity: true)
        }
    }

    
    func isAffected(by affectType: AffectType) -> Bool {
        for affect in affects {
            if affect.type == affectType {
                return true
            }
        }
        return false
    }

    
//    func affected(bySkill skill: Skill) -> Bool {
//        for affect in affects {
//            if case .skill(let v) = affect.type,
//                    v == skill {
//                return true
//            }
//        }
//        return false
//    }
    
//    private func getSlotsForCircle(_ circle: UInt8) -> [Slot] {
//        if let slots = slotsForCircle[circle] {
//            return slots
//        } else {
//            let slots = [Slot]()
//            slotsForCircle[circle] = slots
//            return slots
//        }
//    }
}

extension Creature: Equatable {
    static func ==(lhs: Creature, rhs: Creature) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension Creature: Hashable {
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}

extension Creature: CustomDebugStringConvertible {
    var debugDescription: String {
        guard let vnum = mobile?.vnum else {
            return "$<\(nameNominative.full)>"
        }
        return "$\(vnum)"
    }
}
