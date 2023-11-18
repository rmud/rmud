import Foundation

class Item {
    var prototype: ItemPrototype
    var uid: UInt64

    var vnum: Int

    var ownerUid: UInt64? // uid создателя или nil для нормальных вещей
    var nameNominative = MultiwordName("")
    var nameGenitive = MultiwordName("")
    var nameDative = MultiwordName("")
    var nameAccusative = MultiwordName("")
    var nameInstrumental = MultiwordName("")
    var namePrepositional = MultiwordName("")
    func setNames(_ compressed: String, isAnimate: Bool) {
        let names = endings.decompress(names: compressed, isAnimate: isAnimate)
        nameNominative = MultiwordName(names[0])
        nameGenitive = MultiwordName(names[1])
        nameDative = MultiwordName(names[2])
        nameAccusative = MultiwordName(names[3])
        nameInstrumental = MultiwordName(names[4])
        namePrepositional = MultiwordName(names[5])
    }
    var synonyms: [String] = []
    var groundDescription = "" // When in room
    
    var description: [String] = [] // For look at obj
    var legend: [String] = [] // для показа по "знанию свойств"

    var extraDescriptions: [ExtraDescription] = []

    var gender: Gender = .neuter
    var extraDataByItemType: [ItemType: ItemExtraDataType] = [:]

    var material: Material

    var wearFlags: ItemWearFlags = [] // Where you can wear it
    var extraFlags: ItemExtraFlags = [] // If it hums, glows, etc. bitv
    var restrictFlags: ItemAccessFlags = [] // Item restrictions
    var stateFlags: ItemStateFlags = [] // Item states: noaffects, bow string etc.
    
    var isCursed: Bool { return extraFlags.contains(.cursed) && !extraFlags.contains(.uncursed) }

    var weight = 0 // Weight
    func weightWithContents() -> Int {
        var totalWeight = weight
        
        // Process liquids:
        if let vessel = asVessel() {
            totalWeight += Int(vessel.usedCapacity)
        }
        if let fountain = asFountain() {
            totalWeight += Int(fountain.usedCapacity)
        }
        
        // For containers:
        // TODO учитывать свойство контейнера УДОБСТВО
        for item in contains {
            totalWeight = item.weightWithContents() // recursive call
        }
        return totalWeight
    }
    var cost = 0 // Value when sold (coins)

    var decayTimerTicsLeft: Int? = nil // Decay timer, nil - never decays
    var isDecayTimerEnabled = false
    var groundTimerTicsLeft: Int? = nil // Decay timer on ground, nil - never decays
    var isGroundTimerEnabled: Bool { return groundTimerTicsLeft != nil }
    var isUntouchedByPlayers: Bool {
        !isDecayTimerEnabled && !isGroundTimerEnabled
    }
    
    var qualityPercentage: UInt16 = 100 // can go over 100
    var maxCondition: Int
    var condition: Int
    func conditionPercentage() -> Int {
        return (100 * condition) / maxCondition
    }

    var affects: Set<AffectType> = [] // Creature affects
    var inRoom: Room? // In what room?
    var isInRoom: Bool { return inRoom != nil }
    var carriedBy: Creature? // Carried by?
    var isCarried: Bool { return carriedBy != nil }
    var wornBy: Creature? // Worn by?
    var isWornBySomeone: Bool { return wornBy != nil }
    var wornPosition: EquipmentPosition? = nil
    var inContainer: Item? // In what item?
    var isInContainer: Bool { return inContainer != nil }
    var contains: [Item] = [] // Contains items
    
    var location: String {
        if isCarried {
            return "в руках"
        } else if isInRoom {
            return "в комнате"
        } else if isWornBySomeone {
            return "в экипировке"
        } else if let container = inContainer {
            return "в \(container.namePrepositional.full)"
        }
        return "неизвестно где"
    }

    init(prototype: ItemPrototype, uid: UInt64?, db: Db /*, in area: Area?*/) {
        self.prototype = prototype
        self.uid = uid ?? db.createItemUid()

        vnum = prototype.vnum
        
        nameNominative = MultiwordName(prototype.nameNominative)
        nameGenitive = MultiwordName(prototype.nameGenitive)
        nameDative = MultiwordName(prototype.nameDative)
        nameAccusative = MultiwordName(prototype.nameAccusative)
        nameInstrumental = MultiwordName(prototype.nameInstrumental)
        namePrepositional = MultiwordName(prototype.namePrepositional)
        synonyms = prototype.synonyms.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        groundDescription = prototype.groundDescription
        
        description = prototype.description
        legend = prototype.legend
        
        extraDescriptions = prototype.extraDescriptions
        
        gender = prototype.gender ?? gender
        extraDataByItemType = prototype.extraDataByItemType
        
        material = prototype.material

        // TODO: barricade?

        wearFlags = prototype.wearFlags
        extraFlags = prototype.extraFlags
        restrictFlags = prototype.restrictFlags
        
        weight = prototype.weight
        cost = prototype.cost ?? cost
        
        decayTimerTicsLeft = prototype.decayTimerTics
        
        qualityPercentage = prototype.qualityPercentage ?? qualityPercentage
        maxCondition = material.maxCondition * Int(qualityPercentage) / 100
        condition = maxCondition
        
        affects = prototype.affects
        
        db.itemsInGame.append(self)
        db.itemsCountByVnum[prototype.vnum]? += 1
        db.itemsByUid[self.uid] = self

        /*
            {Name,         vtSTRING, vaREQUIRED, &prs_obj.name, NO_SPEC},
        {"синонимы",   vtSTRING, 0, &prs_obj.syns, NO_SPEC},
        {"строка",     vtSTRING, vaREQUIRED, &prs_obj.ground_descr, NO_SPEC},
        {Descr,        vtTEXT, vaREQUIRED, &prs_obj.description, NO_SPEC},
        {"знание",     vtTEXT, 0, &prs_obj.legend_text, NO_SPEC},
        {"вес",        vtLONG, vaREQUIRED, &prs_obj.weight, NO_SPEC},
        {"род",        vtBYTE, vaREQUIRED, &prs_obj.gender, NO_SPEC},
        {"тип",        vtBYTE, vaREQUIRED, &prs_obj.type_flag, NO_SPEC},
        {"цена",       vtLONG, vaREQUIRED, &prs_obj.cost, NO_SPEC},
        {"материал",   vtBYTE, vaREQUIRED, &prs_obj.material, NO_SPEC},
        {"качество",   vtLONG, 0, &prs_obj.quality, NO_SPEC},
        {"износ",      vtLONG, vaRANGE, &range_wear, NO_SPEC},
        {"использование", vtDWORD, 0, &prs_obj.wear_flags, NO_SPEC},
        {"запрет",     vtDWORD, 0, &prs_obj.restrict_flags, NO_SPEC},
        {"разрешение", vtDWORD, vaFUNC, (void*)prs_f_item_allow, NO_SPEC},
        {"пэффекты",   vtWORD, vaLIST, (void*)prs_w_oaffects, NO_SPEC},
        {"влияние",    vtDWORD, vaVALLIST, (void*)prs_w_oapply, NO_SPEC},
        {"жизнь",      vtLONG, 0, &prs_obj.timer, NO_SPEC},
        {"предел",     vtLONG, 0, &prs_obj.load_max, NO_SPEC},
        {"шанс",       vtBYTE, 0, &prs_obj.load_chance, NO_SPEC},
        {"починка",    vtBYTE, 0, &prs_obj.repair_lev, NO_SPEC},
        {"псвойства",  vtLONG, 0, &prs_obj.extra_flags, NO_SPEC},
        {"содержимое", vtDWORD, vaVALLIST, (void*)prs_w_contents, NO_SPEC},
        {"деньги",     vtSHORT, vaFUNC, (void*)prs_f_money_obj, NO_SPEC},
        {Extra_key,    vtSTRING, vaPRIME, &prs_edesc.keyword, SPC_EDESC},
        {Extra_text,   vtTEXT, 0, &prs_edesc.description, SPC_EDESC},
        {Proc,         vtLONG, vaLIST, (void*)prs_w_trig, NO_SPEC},
        /* "универсальные" ячейки */
        {"знач0", vtLONG, 0, &prs_obj.value[0], NO_SPEC},
        {"знач1", vtLONG, 0, &prs_obj.value[1], NO_SPEC},
        {"знач2", vtLONG, 0, &prs_obj.value[2], NO_SPEC},
        {"знач3", vtLONG, 0, &prs_obj.value[3], NO_SPEC},
        {"знач4", vtLONG, 0, &prs_obj.value[4], NO_SPEC},
        /* для светильников */
        {"свет", vtLONG, 0, &prs_obj.value[2], NO_SPEC},
        /* для свитков */
        {"уровень", vtLONG, 0, &prs_obj.value[0], NO_SPEC}, // так же для жезлов и посохов
        {"закл1", vtLONG, 0, &prs_obj.value[1], NO_SPEC},
        {"закл2", vtLONG, 0, &prs_obj.value[2], NO_SPEC},
        {"закл3", vtLONG, 0, &prs_obj.value[3], NO_SPEC},
        /* для wand'ов и staff'ов */
        {"заряды", vtLONG, vaFUNC, (void*)prs_f_charges, NO_SPEC}, // value[1] и value[2]
        {"заклинание", vtLONG, 0, &prs_obj.value[3], NO_SPEC},
        /* для оружия */
        {"волшебство", vtLONG, 0, &prs_obj.value[0], NO_SPEC},
        {"вред", vtLONG, vaLIST, (void*)prs_w_odam, NO_SPEC},
        {"удар", vtLONG, 0, &prs_obj.value[3], NO_SPEC},
        /* для доспехов */
        {"прочность", vtLONG, 0, &prs_obj.value[0], NO_SPEC},
        {"доспех", vtLONG, 0, &prs_obj.value[1], NO_SPEC},
        /* для еды */
        {"насыщение", vtLONG, 0, &prs_obj.value[0], NO_SPEC},
        {"влажность", vtLONG, 0, &prs_obj.value[2], NO_SPEC},
        /* для контейнеров */
        {"вместимость", vtLONG, 0, &prs_obj.value[0], NO_SPEC},
        {"косвойства", vtLONG, 0, &prs_obj.value[1], NO_SPEC},
        {"ключ", vtLONG, 0, &prs_obj.value[2], NO_SPEC},
        {"удобство", vtLONG, 0, &prs_obj.value[3], NO_SPEC},
        {"косложность", vtLONG, vaRANGE, &range_contlock, NO_SPEC},
        /* три значения для сосудов и фонтанов */
        {"емкость", vtLONG, vaFUNC, (void*)prs_f_drinks, NO_SPEC}, // value[0] и value[1]
        {"жидкость", vtLONG, 0, &prs_obj.value[2], NO_SPEC},
        {"яд", vtLONG, 0, &prs_obj.value[3], NO_SPEC},  // также действует и для еды
        /* для денег */
        {"сумма", vtLONG, 0, &prs_obj.value[0], NO_SPEC},
        /* для досок */
        {"номер", vtLONG, 0, &prs_obj.value[0], NO_SPEC},
        {"чтение", vtLONG, 0, &prs_obj.value[1], NO_SPEC},
        {"запись", vtLONG, 0, &prs_obj.value[2], NO_SPEC},
        /*  */
        /* ПЕРЕХВАТ команд */
        {Ovr_cmd, vtSHORT, vaPRIME, &prs_ovr.opcode, SPC_OVR},
        {Ovr_player, vtSTRING, 0, &prs_ovr.msg_to_char, SPC_OVR},
        {Ovr_victim, vtSTRING, 0, &prs_ovr.msg_to_vict, SPC_OVR},
        {Ovr_others, vtSTRING, 0, &prs_ovr.msg_to_notvict, SPC_OVR},
        {Ovr_room, vtSTRING, 0, &prs_ovr.msg_to_room, SPC_OVR},
        /* Триггеры
         {"триггер.событие", vtSTRING, vaPRIME, &prs_trig.event, SPC_TRIG},
         {"триггер.функция", vtSTRING, 0, &prs_trig.func, SPC_TRIG}, */
        /* */
        {"скакун",  vtLONG, 0, &prs_obj.value[0], NO_SPEC},
        {"конюх1",  vtLONG, 0, &prs_obj.value[1], NO_SPEC},
        {"конюх2",  vtLONG, 0, &prs_obj.value[2], NO_SPEC},
        {"конюх3",  vtLONG, 0, &prs_obj.value[3], NO_SPEC},
        {"конюшня", vtLONG, 0, &prs_obj.value[4], NO_SPEC},
        /* */
        {"текст", vtTEXT, 0, &prs_obj.note_text, NO_SPEC}
        */
    }
}

extension Item: Equatable {
    static func ==(lhs: Item, rhs: Item) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension Item: Hashable {
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}

extension Item: CustomDebugStringConvertible {
    var debugDescription: String {
        return "@\(vnum)"
    }
}
