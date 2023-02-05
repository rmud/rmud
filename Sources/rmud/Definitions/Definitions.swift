import Foundation

class Definitions {
    let enumerations = Enumerations()
    let areaFields: FieldDefinitions
    let roomFields: FieldDefinitions
    let mobileFields: FieldDefinitions
    let itemFields: FieldDefinitions
    let socialFields: FieldDefinitions

    init() {
        areaFields = FieldDefinitions(enumerations: enumerations)
        roomFields = FieldDefinitions(enumerations: enumerations)
        mobileFields = FieldDefinitions(enumerations: enumerations)
        itemFields = FieldDefinitions(enumerations: enumerations)
        socialFields = FieldDefinitions(enumerations: enumerations)
    }

    func registerEnumerations() throws {
        let e = enumerations
        
        AffectType.registerDefinitions(in: e)
        Apply.registerDefinitions(in: e)
        AreaResetCondition.registerDefinitions(in: e)
        ClassId.registerDefinitions(in: e)
        ContainerFlags.registerDefinitions(in: e)
        Direction.registerDefinitions(in: e)
        Liquid.registerDefinitions(in: e)
        EventActionFlags.registerDefinitions(in: e)
        ExitFlags.registerDefinitions(in: e)
        ExitType.registerDefinitions(in: e)
        Frag.registerDefinitions(in: e)
        Gender.registerDefinitions(in: e)
        HitType.registerDefinitions(in: e)
        ItemEventId.registerDefinitions(in: e)
        ItemExtraFlags.registerDefinitions(in: e)
        ItemAccessFlags.registerDefinitions(in: e)
        ItemType.registerDefinitions(in: e)
        ItemTypeFlagsDeprecated.registerDefinitions(in: e)
        ItemWearFlags.registerDefinitions(in: e)
        LockCondition.registerDefinitions(in: e)
        Material.registerDefinitions(in: e)
        MobileEventId.registerDefinitions(in: e)
        MobileFlags.registerDefinitions(in: e)
        MovementType.registerDefinitions(in: e)
        Position.registerDefinitions(in: e)
        Race.registerDefinitions(in: e)
        RoomEventId.registerDefinitions(in: e)
        RoomFlags.registerDefinitions(in: e)
        Skill.registerDefinitions(in: e)
        SocialRestrictionFlags.registerDefinitions(in: e)
        SpecialAttackType.registerDefinitions(in: e)
        SpecialAttackUsageFlags.registerDefinitions(in: e)
        Spell.registerDefinitions(in: e)
        Terrain.registerDefinitions(in: e)
        WeaponType.registerDefinitions(in: e)
    }
    
    func registerAreaFields() throws {
        let d = areaFields
        
        // Required fields
        try d.insert(name: "область", type: .line, flags: [.entityId, .required])
        try d.insert(name: "описание", type: .line, flags: .required)
        try d.insert(name: "сброс.условие", type: .enumeration, flags: [.required, .structureStart] )
        try d.insert(name: "сброс.период", type: .number, flags: .required )
        try d.insert(name: "комнаты.первая", type: .number, flags: [.required, .structureStart])
        try d.insert(name: "комнаты.последняя", type: .number, flags: .required)
        
        // Optional fields
        try d.insert(name: "комнаты.основная", type: .number)
        try d.insert(name: "комментарий", type: .longText)
        try d.insert(name: "путь.название", type: .line, flags: [.required, .structureStart])
        try d.insert(name: "путь.комнаты", type: .list)
    }
    
    func registerItemFields() throws {
        let d = itemFields

        try d.insert(name: "предмет", type: .number, flags: [.entityId, .required])

        // Required fields
        try d.insert(name: "название", type: .line, flags: .required)
        try d.insert(name: "материал", type: .enumeration, flags: .required)
        try d.insert(name: "вес", type: .number, flags: .required)
        
        // Optional fields
        try d.insert(name: "влияние", type: .dictionary)
        try d.insert(name: "деньги", type: .number)
        try d.insert(name: "дополнительно.ключ", type: .line, flags: .structureStart)
        try d.insert(name: "дополнительно.текст", type: .longText, flags: .required)
        try d.insert(name: "жизнь", type: .number) // TODO: make required?
        try d.insert(name: "запрет", type: .flags)
        try d.insert(name: "знание", type: .longText)
        // износ предмета - временно пишется в "текущее состояние"
        try d.insert(name: "износ", type: .constrainedNumber(0...100))
        try d.insert(name: "использование", type: .flags)
        try d.insert(name: "качество", type: .number)
        try d.insert(name: "комментарий", type: .longText)
        try d.insert(name: "описание", type: .longText)
        try d.insert(name: "пперехват.событие", type: .enumeration, flags: .structureStart)
        try d.insert(name: "пперехват.выполнение", type: .enumeration)
        try d.insert(name: "пперехват.игроку", type: .line)
        try d.insert(name: "пперехват.жертве", type: .line)
        try d.insert(name: "пперехват.комнате", type: .line)
        try d.insert(name: "починка", type: .number)
        try d.insert(name: "предел", type: .number)
        try d.insert(name: "процедура", type: .list)
        try d.insert(name: "пэффекты", type: .list)
        try d.insert(name: "псвойства", type: .flags)
        try d.insert(name: "разрешение", type: .flags)
        try d.insert(name: "род", type: .enumeration)
        try d.insert(name: "синонимы", type: .line)
        try d.insert(name: "содержимое", type: .dictionary)
        try d.insert(name: "строка", type: .line)
        try d.insert(name: "цена", type: .number)
        try d.insert(name: "шанс", type: .number)

        // Fields for different item types
        // Used for item types without parameters: treasure, worn, other, key, pen, boat, token, or even default container
        try d.insert(name: "тип", type: .list)
        // Light
        try d.insert(name: "свет.время", type: .number, flags: .structureAutoCreate)
        // Scroll
        try d.insert(name: "свиток.заклинания", type: .dictionary, flags: .structureAutoCreate)
        // Wand
        try d.insert(name: "палочка.заклинания", type: .dictionary, flags: .structureAutoCreate)
        try d.insert(name: "палочка.заряды", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "палочка.осталось", type: .number, flags: .structureAutoCreate)
        // Staff
        try d.insert(name: "жезл.заклинания", type: .dictionary, flags: .structureAutoCreate)
        try d.insert(name: "жезл.заряды", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "жезл.осталось", type: .number, flags: .structureAutoCreate)
        // Weapon
        try d.insert(name: "оружие.вред", type: .dice, flags: .structureAutoCreate)
        try d.insert(name: "оружие.удар", type: .enumeration, flags: .structureAutoCreate)
        try d.insert(name: "оружие.яд", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "оружие.волшебство", type: .number, flags: .structureAutoCreate) // не используется
        // Treasure
        // Armor
        try d.insert(name: "доспех.прочность", type: .number, flags: .structureAutoCreate)
        // Potion
        try d.insert(name: "зелье.заклинания", type: .dictionary, flags: .structureAutoCreate)
        // Worn
        // Other
        // Container
        try d.insert(name: "контейнер.вместимость", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "контейнер.свойства", type: .flags, flags: .structureAutoCreate)
        try d.insert(name: "контейнер.яд", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "контейнер.монстр", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "контейнер.удобство", type: .number, flags: .structureAutoCreate) // FIXME: unused
        try d.insert(name: "контейнер.замок_ключ", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "контейнер.замок_сложность", type: .constrainedNumber(0...150), flags: .structureAutoCreate)
        try d.insert(name: "контейнер.замок_состояние", type: .enumeration, flags: .structureAutoCreate)
        try d.insert(name: "контейнер.замок_повреждение", type: .number, flags: .structureAutoCreate)
        // Note
        try d.insert(name: "записка.текст", type: .longText, flags: .structureAutoCreate)
        // Vessel
        try d.insert(name: "сосуд.емкость", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "сосуд.осталось", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "сосуд.жидкость", type: .enumeration, flags: .structureAutoCreate)
        try d.insert(name: "сосуд.яд", type: .number, flags: .structureAutoCreate)
        // Key
        // Food
        try d.insert(name: "пища.насыщение", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "пища.влажность", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "пища.яд", type: .number, flags: .structureAutoCreate)
        // Money
        // Pen
        // Boat
        // Fountatin
        // Spellbook
        try d.insert(name: "книга.заклинания", type: .dictionary, flags: .structureAutoCreate)
        // Board
        try d.insert(name: "доска.номер", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "доска.чтение", type: .number, flags: .structureAutoCreate)
        try d.insert(name: "доска.запись", type: .number, flags: .structureAutoCreate)
        // Receipt
        // Token

        // Deprecated in favor of ЗНАЧЕНИЯ.*
        // знач* are used by bulletin boards
        try d.insert(name: "знач0", type: .number, flags: .deprecated)
        try d.insert(name: "знач1", type: .number, flags: .deprecated)
        try d.insert(name: "знач2", type: .number, flags: .deprecated)
        try d.insert(name: "свет", type: .number, flags: .deprecated) // light: ЗНАЧ2
        try d.insert(name: "уровень", type: .number, flags: .deprecated) // scroll, wand, staff, potion: ЗНАЧ0
        try d.insert(name: "закл1", type: .enumeration, flags: .deprecated) // scroll, potion, spellbook: ЗНАЧ1
        try d.insert(name: "закл2", type: .enumeration, flags: .deprecated) // scroll, potion, spellbook: ЗНАЧ2
        try d.insert(name: "закл3", type: .enumeration, flags: .deprecated) // scroll, potion, spellbook: ЗНАЧ3
        try d.insert(name: "заряды", type: .number, flags: .deprecated) // wand, staff: ЗНАЧ1 и ЗНАЧ2
        try d.insert(name: "заклинание", type: .enumeration, flags: .deprecated) // wand, staff: ЗНАЧ3
        try d.insert(name: "волшебство", type: .number, flags: .deprecated) // weapon: ЗНАЧ0 -- не используется
        try d.insert(name: "вред", type: .dice, flags: .deprecated) // weapon: ЗНАЧ1 d ЗНАЧ2 + ЗНАЧ4
        try d.insert(name: "удар", type: .enumeration, flags: .deprecated) // weapon: ЗНАЧ3
        try d.insert(name: "прочность", type: .number, flags: .deprecated) // armor: ЗНАЧ0
        //try d.insert(name: "доспех", type: .number, flags: .deprecated) // armor: ЗНАЧ1 - unused
        try d.insert(name: "вместимость", type: .number, flags: .deprecated) // container: ЗНАЧ0
        try d.insert(name: "косвойства", type: .flags, flags: .deprecated) // container: ЗНАЧ1
        try d.insert(name: "ключ", type: .number, flags: .deprecated) // container: ЗНАЧ2
        try d.insert(name: "удобство", type: .number) // container: ЗНАЧ3
        try d.insert(name: "косложность", type: .constrainedNumber(0...150), flags: .deprecated) // container: ЗНАЧ4
        try d.insert(name: "текст", type: .longText, flags: .deprecated) // note: ТЕКСТ
        try d.insert(name: "емкость", type: .number, flags: .deprecated) // vessel, fountain: ЗНАЧ0, ЗНАЧ1
        try d.insert(name: "жидкость", type: .enumeration, flags: .deprecated) // vessel, fountain: ЗНАЧ2
        // для оружия ЯД сейчас нельзя указывать в файлах мира и он был реализован отдельным полем poison_lev. я его перенес в ItemExtraData.Weapon т.к. логически он относится туда и в будущем можно будет разрешить его указывать.
        try d.insert(name: "яд", type: .number, flags: .deprecated) // vessel, fountain, food: ЗНАЧ3
        try d.insert(name: "насыщение", type: .number, flags: .deprecated) // food: ЗНАЧ0
        try d.insert(name: "влажность", type: .number, flags: .deprecated) // food: ЗНАЧ2
        try d.insert(name: "сумма", type: .number, flags: .deprecated) // money: ЗНАЧ0
        try d.insert(name: "номер", type: .number, flags: .deprecated) // board: ЗНАЧ0
        try d.insert(name: "чтение", type: .number, flags: .deprecated) // board: ЗНАЧ1
        try d.insert(name: "запись", type: .number, flags: .deprecated) // board: ЗНАЧ2
        try d.insert(name: "скакун", type: .number) // receipt: ЗНАЧ0
        try d.insert(name: "конюх1", type: .number) // receipt: ЗНАЧ1
        try d.insert(name: "конюх2", type: .number) // receipt: ЗНАЧ2
        try d.insert(name: "конюх3", type: .number) // receipt: ЗНАЧ3
        try d.insert(name: "конюшня", type: .number) // receipt: ЗНАЧ4
    }
    
    func registerRoomFields() throws {
        let d = roomFields

        try d.insert(name: "комната", type: .number, flags: [.entityId, .required])
        
        // Required fields
        try d.insert(name: "местность", type: .enumeration, flags: .required)
        try d.insert(name: "название", type: .line, flags: .required)
        try d.insert(name: "описание", type: .longText, flags: .required)

        // Directions
        for direction in Direction.orderedDirections.map({ $0.nameForAreaFile }) {
            try d.insert(name: "\(direction)", type: .number)
            try d.insert(name: "\(direction).комната", type: .number, flags: .structureAutoCreate)
            try d.insert(name: "\(direction).тип", type: .enumeration, flags: .structureAutoCreate)
            try d.insert(name: "\(direction).признаки", type: .flags, flags: .structureAutoCreate)
            try d.insert(name: "\(direction).замок_ключ", type: .number, flags: .structureAutoCreate)
            try d.insert(name: "\(direction).замок_сложность", type: .constrainedNumber(0...150), flags: .structureAutoCreate)
            try d.insert(name: "\(direction).замок_состояние", type: .enumeration, flags: .structureAutoCreate)
            try d.insert(name: "\(direction).замок_повреждение", type: .number, flags: .structureAutoCreate)
            try d.insert(name: "\(direction).расстояние", type: .constrainedNumber(1...10), flags: .structureAutoCreate)
            try d.insert(name: "\(direction).описание", type: .line, flags: .structureAutoCreate)
        }
        
        // Optional fields
        try d.insert(name: "деньги", type: .number)
        try d.insert(name: "дополнительно.ключ", type: .line, flags: .structureStart)
        try d.insert(name: "дополнительно.текст", type: .longText, flags: .required)
        try d.insert(name: "монстры", type: .dictionary)
        try d.insert(name: "комментарий", type: .longText)
        try d.insert(name: "кперехват.событие", type: .enumeration, flags: .structureStart)
        try d.insert(name: "кперехват.выполнение", type: .enumeration)
        try d.insert(name: "кперехват.игроку", type: .line)
        try d.insert(name: "кперехват.жертве", type: .line)
        try d.insert(name: "кперехват.комнате", type: .line)
        try d.insert(name: "ксвойства", type: .flags)
        try d.insert(name: "легенда.название", type: .line, flags: .structureStart)
        try d.insert(name: "легенда.символ", type: .line)
        try d.insert(name: "предметы", type: .dictionary)
        try d.insert(name: "процедура", type: .list)
        
        // Deprecated fields:
        try d.insert(name: "осевер", type: .line, flags: .deprecated)
        try d.insert(name: "оюг", type: .line, flags: .deprecated)
        try d.insert(name: "озапад", type: .line, flags: .deprecated)
        try d.insert(name: "овосток", type: .line, flags: .deprecated)
        try d.insert(name: "овверх", type: .line, flags: .deprecated)
        try d.insert(name: "овниз", type: .line, flags: .deprecated)
        try d.insert(name: "проход.направление", type: .enumeration, flags: [.structureStart, .deprecated])
        try d.insert(name: "проход.ключ", type: .number, flags: .deprecated)
        try d.insert(name: "проход.признаки", type: .flags, flags: .deprecated)
        try d.insert(name: "проход.сложность", type: .constrainedNumber(0...150), flags: .deprecated)
        try d.insert(name: "проход.тип", type: .enumeration, flags: .deprecated)
        try d.insert(name: "проход.расстояние", type: .constrainedNumber(1...10), flags: .deprecated)
    }
    
    func registerMobileFields() throws {
        let d = mobileFields

        try d.insert(name: "монстр", type: .number, flags: [.entityId, .required])
        
        // Required fields
        try d.insert(name: "атака", type: .number, flags: .required)
        try d.insert(name: "вред1", type: .dice, flags: .required)
        try d.insert(name: "жизнь", type: .number, flags: .required)
        try d.insert(name: "защита", type: .number, flags: .required)
        try d.insert(name: "имя", type: .line, flags: .required)
        try d.insert(name: "наклонности", type: .constrainedNumber(-1000...1000), flags: .required)
        try d.insert(name: "опыт", type: .number, flags: .required)
        try d.insert(name: "пол", type: .enumeration, flags: .required)
        try d.insert(name: "профессия", type: .enumeration, flags: .required)
        try d.insert(name: "строка", type: .line, flags: .required)
        try d.insert(name: "уровень", type: .number, flags: .required)
        try d.insert(name: "описание", type: .longText, flags: .required)
        try d.insert(name: "раса", type: .enumeration, flags: .required)

        // Optional fields
        // это поле потом (уже после проверок) будет уменьшено на 1, если оно > 0, увеличено на 1, если < 0 // FIXME разобраться
        try d.insert(name: "атаки1", type: .constrainedNumber(-99...99))
        // в отличие от extra_attack его уменьшать не надо
        try d.insert(name: "атаки2", type: .constrainedNumber(-99...99))
        try d.insert(name: "вес", type: .constrainedNumber(0...2048))
        try d.insert(name: "вред2", type: .dice)
        try d.insert(name: "деньги", type: .dice)
        try d.insert(name: "дополнительно.ключ", type: .line, flags: .structureStart)
        try d.insert(name: "дополнительно.текст", type: .longText, flags: .required)
        try d.insert(name: "заклинания", type: .list)
        try d.insert(name: "заучивание", type: .dictionary)
        try d.insert(name: "здоровье", type: .constrainedNumber(0...200))
        try d.insert(name: "зкислота", type: .number)
        try d.insert(name: "змагия", type: .number)
        try d.insert(name: "зхолод", type: .number)
        try d.insert(name: "зогонь", type: .number)
        try d.insert(name: "зудар", type: .number)
        try d.insert(name: "зэлектричество", type: .number)
        try d.insert(name: "иммунитет", type: .number)
        try d.insert(name: "инвентарь", type: .dictionary)
        // Deprecated
        try d.insert(name: "команда", type: .line, flags: .deprecated)
        try d.insert(name: "комментарий", type: .longText)
        try d.insert(name: "ловкость", type: .constrainedNumber(3...36))
        try d.insert(name: "магазин.продажа", type: .number, flags: .structureStart)
        try d.insert(name: "магазин.запрет", type: .flags)
        try d.insert(name: "магазин.меню", type: .list)
        try d.insert(name: "магазин.покупка", type: .number)
        try d.insert(name: "магазин.починка", type: .number)
        try d.insert(name: "магазин.товар", type: .flags)
        try d.insert(name: "мсвойства", type: .flags)
        try d.insert(name: "мудрость", type: .constrainedNumber(3...36))
        try d.insert(name: "мэффекты", type: .list)
        try d.insert(name: "конюх", type: .number)
        try d.insert(name: "перемещение", type: .enumeration)
        try d.insert(name: "поглощение", type: .number)
        try d.insert(name: "положение", type: .enumeration)
        try d.insert(name: "посмертно", type: .dictionary)
        try d.insert(name: "предел", type: .number)
        try d.insert(name: "процедура", type: .list)
        try d.insert(name: "путь", type: .line)
        try d.insert(name: "размер", type: .constrainedNumber(0...127))
        try d.insert(name: "разум", type: .constrainedNumber(3...36))
        try d.insert(name: "рост", type: .constrainedNumber(0...255))
        try d.insert(name: "сила", type: .constrainedNumber(3...36))
        try d.insert(name: "синонимы", type: .line)
        try d.insert(name: "спец.тип", type: .enumeration, flags: .structureStart)
        try d.insert(name: "спец.врагам", type: .line)
        try d.insert(name: "спец.вред", type: .dice)
        try d.insert(name: "спец.друзьям", type: .line)
        try d.insert(name: "спец.заклинание", type: .enumeration)
        try d.insert(name: "спец.игроку", type: .line)
        try d.insert(name: "спец.комнате", type: .line)
        try d.insert(name: "спец.применение", type: .flags)
        try d.insert(name: "спец.разрушение", type: .enumeration)
        try d.insert(name: "спец.уровень", type: .number)
        try d.insert(name: "телосложение", type: .constrainedNumber(3...36))
        try d.insert(name: "труп.имя", type: .line, flags: .structureStart)
        try d.insert(name: "труп.материал", type: .enumeration)
        try d.insert(name: "труп.описание", type: .longText)
        try d.insert(name: "труп.род", type: .enumeration)
        try d.insert(name: "труп.строка", type: .line)
        try d.insert(name: "трусость", type: .constrainedNumber(0...100))
        try d.insert(name: "удар1", type: .enumeration)
        try d.insert(name: "удар2", type: .enumeration)
        try d.insert(name: "умения", type: .dictionary)
        try d.insert(name: "хватка", type: .constrainedNumber(0...100))
        try d.insert(name: "шанс", type: .number)
        try d.insert(name: "экипировка", type: .dictionary)
        try d.insert(name: "яд", type: .constrainedNumber(0...127)) // ядовитость трупа
    }
    
    func registerSocialFields() throws {
        let d = socialFields
        
        try d.insert(name: "действие", type: .line, flags: [.entityId, .required])
        
        // Required fields
        try d.insert(name: "положение", type: .enumeration, flags: .required)
        
        // Optional fields
        try d.insert(name: "дограничения", type: .flags)
        try d.insert(name: "наречие", type: .line)
        try d.insert(name: "игроку", type: .line)
        try d.insert(name: "комментарий", type: .longText)
        try d.insert(name: "комнате", type: .line)
        try d.insert(name: "цель.положение", type: .enumeration, flags: .structureStart)
        try d.insert(name: "цель.дограничения", type: .flags)
        try d.insert(name: "цель.игроку", type: .line)
        try d.insert(name: "цель.комнате", type: .line)
        try d.insert(name: "цель.цели", type: .line)
        try d.insert(name: "цель.себяигроку", type: .line)
        try d.insert(name: "цель.себякомнате", type: .line)
    }
    
    func dumpToFile(named filename: String) throws {
        try dumpAll().write(toFile: filename, atomically: settings.saveFilesAtomically, encoding: .utf8)
    }
    
    func dumpAll() -> String {
        var result = ""
        
        append(section: dump(areaFields, name: "ОБЛАСТЬ"), to: &result)
        append(section: dump(roomFields, name: "КОМНАТА"), to: &result)
        append(section: dump(mobileFields, name: "МОНСТР"), to: &result)
        append(section: dump(itemFields, name: "ПРЕДМЕТ"), to: &result)
        append(section: dump(socialFields, name: "ДЕЙСТВИЕ"), to: &result)
        append(section: dump(enumerations, name: "КОНСТАНТЫ"), to: &result)

        return result
    }
    
    private func dump(_ d: FieldDefinitions, name: String) -> String {
        var result = "[\(name)]\n\n"
        
        for fieldName in d.fieldsByLowercasedName.keys.sorted() {
            result += fieldName.uppercased().rightExpandingTo(20)
            result += " "
            result += "\n"
        }
        
        return result
    }

    private func dump(_ e: Enumerations, name: String) -> String {
        var result = "[\(name)]\n\n"
        
        // Uppercase aliases and turn them into strings:
        let array = e.enumSpecs.map {
            return ($0.aliases.map{ $0.uppercased() }.joined(separator: " "), $0.valuesByLowercasedName)
        }
        let sorted = array.sorted { $0.0 < $1.0 }
        
        var isFirst = true
        for (aliasesString, valuesByName) in sorted {
            if isFirst {
                isFirst = false
            } else {
                result += "\n"
            }
            
            result += aliasesString
            result += "\n"
            for name in valuesByName.keys.sorted() {
                guard let value = valuesByName[name] else { fatalError() }
                result += "  " + (name.uppercased() + " ").rightExpandingTo(30, with: ".")
                result += " "
                result += String(value)
                result += "\n"
            }
        }
        
        return result
    }

    private func append(section: String, to: inout String) {
        if !to.isEmpty {
            to += "\n"
        }
        to += section
    }
}

