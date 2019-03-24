import Foundation

enum Apply: RawRepresentable, Hashable, Equatable {
    case none // No effect
    case skill(Skill)
    case spell(Spell)
    case slotCount(circle: UInt8) // used to be 423...431
    case custom(ApplyCustom)
    
    init?(rawValue: UInt16) {
        if 0 == rawValue {
            self = .none
        } else if let skill = Skill(rawValue: rawValue) {
            self = .skill(skill)
        } else if let spell = Spell(rawValue: rawValue) {
            self = .spell(spell)
        } else if 423...431 ~= rawValue {
            guard let circle = UInt8(exactly: rawValue - 423 + 1) else { return nil }
            self = .slotCount(circle: circle)
        } else if let custom = ApplyCustom(rawValue: rawValue) {
            self = .custom(custom)
        } else {
            return nil
        }
    }
    
    var rawValue: UInt16 {
        switch self {
        case .none: return 0
        case .skill(let skill): return skill.rawValue
        case .spell(let spell): return spell.rawValue
        case .slotCount(let circle): return UInt16(circle) - 1 + 423
        case .custom(let applyCustom): return applyCustom.rawValue
        }
    }

    static let aliases = ["влияние"]
    
    static func registerDefinitions(in e: Enumerations) {
        var namesByValue: Enumerations.EnumSpec.NamesByValue = [:]
        
        Skill.definitions.forEach { namesByValue[$0] = $1 }
        Spell.definitions.forEach { namesByValue[$0] = $1 }
        
        namesByValue[423] = "круг1" // Изменение прогрессии круга 1
        namesByValue[424] = "круг2" // Изменение прогрессии круга 2
        namesByValue[425] = "круг3" // Изменение прогрессии круга 3
        namesByValue[426] = "круг4" // Изменение прогрессии круга 4
        namesByValue[427] = "круг5" // Изменение прогрессии круга 5
        namesByValue[428] = "круг6" // Изменение прогрессии круга 6
        namesByValue[429] = "круг7" // Изменение прогрессии круга 7
        namesByValue[430] = "круг8" // Изменение прогрессии круга 8
        namesByValue[431] = "круг9" // Изменение прогрессии круга 9

        ApplyCustom.definitions.forEach { namesByValue[$0] = $1 }
        
        e.add(aliases: aliases, namesByValue: namesByValue)
    }
    
    static func ==(lhs: Apply, rhs: Apply) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public var hashValue: Int { return rawValue.hashValue }
}

enum ApplyCustom: UInt16 {
    case alignmentChange   = 401
    case weight            = 402
    case height            = 403
    case strength          = 404
    case intelligence      = 405
    case wisdom            = 406
    case dexterity         = 407
    case constitution      = 408
    case charisma          = 409
    case health            = 410
    case size              = 411
    case age               = 412
    case learn             = 413
    case damroll           = 414
    case hitPoints         = 415
    case movement          = 416
    case attack            = 417
    case defense           = 418
    case absorb            = 419
    case recuperation      = 420
    case regeneration      = 421
    case alignment         = 422
    case wimpyLevel        = 432
    case savingMagic       = 433
    case savingHeat        = 434
    case savingCold        = 435
    case savingAcid        = 436
    case savingElectricity = 437
    case savingCrush       = 438
    case concentration     = 439
    case savingAll         = 440
    case competence        = 441
    
    static var definitions: Enumerations.EnumSpec.NamesByValue = [
        401: "развитие",       // Изменение наклонностей
        402: "вес",            // Вес
        403: "рост",           // Рост
        404: "сила",           // Сила
        405: "разум",          // Разум
        406: "мудрость",       // Мудрость
        407: "ловкость",       // Ловкость
        408: "телосложение",   // Телосложение
        409: "обаяние",        // Обаяние
        410: "здоровье",       // Здоровье
        411: "размер",         // Размер
        412: "возраст",        // Возраст
        413: "обучение",       // Скорость обучения
        414: "вред",           // Очки вреда
        415: "жизнь",          // Очки жизни
        416: "бодрость",       // Очки бодрости
        417: "атака",          // Класс атаки
        418: "защита",         // Класс защиты
        419: "поглощение",     // Поглощаемый вред
        420: "отдых",          // Скорость восстановления очков бодрости
        421: "лечение",        // Скорость восстановления очков жизни
        422: "наклонности",    // Наклонности
        423: "круг1",          // Изменение прогрессии круга 1
        424: "круг2",          // Изменение прогрессии круга 2
        425: "круг3",          // Изменение прогрессии круга 3
        426: "круг4",          // Изменение прогрессии круга 4
        427: "круг5",          // Изменение прогрессии круга 5
        428: "круг6",          // Изменение прогрессии круга 6
        429: "круг7",          // Изменение прогрессии круга 7
        430: "круг8",          // Изменение прогрессии круга 8
        431: "круг9",          // Изменение прогрессии круга 9
        432: "трусость",       // Трусость
        433: "змагия",         // Защита от магии
        434: "зогонь",         // Защита от огня
        435: "зхолод",         // Защита от холода
        436: "зкислота",       // Защита от кислоты
        437: "зэлектричество", // Защита от электричества
        438: "зудар",          // Защита от ударов, в т.ч. звука
        439: "концентрация",   // Концетрация
        440: "звсямагия",      // Защита от магии и всех стихий
        441: "мастерство",     //  + ко всем умениям (кроме оружия)
    ]
}

