import Foundation

enum Material: UInt8 {
    case tinMetal        = 1
    case bronzeMetal     = 2
    case copperMetal     = 3
    case ironMetal       = 4
    case steelMetal      = 5
    // 6-8 reserved for non-precious metals
    case otherMetal      = 9  // other non-precious metals
    
    case silverMetal     = 10
    case goldMetal       = 11
    case platinumMetal   = 12
    case mithrilMetal    = 13
    case adamantiteMetal = 14
    case preciousMetal   = 15
    // 16-19 reserved for precious metals
    
    case crystal         = 20
    case ice             = 21
    case thinWood        = 22
    case thickWood       = 23
    case ceramic         = 24
    case glass           = 25
    case stone           = 26
    case softStone       = 27 // мягкий камень, типа известняка
    case bone            = 28
    case horn            = 29 // рог, особо прочная (слоновая) кость
    case chitin          = 30
    case plume           = 31 // перья (или одно перо)
    case coral           = 32
    case nacre           = 33 // перламутр, вещество раковин молюсков
    case cloth           = 34
    case thickCloth      = 35 // войлок, толстая шерсть и т.п.
    case leather         = 36
    case fineLeather     = 37 // тонкая кожа
    case hide            = 38 // шкура
    case scale           = 39
    case dragonScale     = 40
    case organic         = 41
    case wax             = 42 // воск и прочие мякие плавкие материалы
    case parchment       = 43
    case paper           = 44
    case jelly           = 45
    case liquid          = 46
    case gasVapour       = 47
    
    static let metals: Set<Material> = [
        tinMetal, bronzeMetal, copperMetal, ironMetal, steelMetal, otherMetal, silverMetal,  goldMetal, platinumMetal, mithrilMetal, adamantiteMetal, preciousMetal ]

    static let preciousMetals: Set<Material> = [
        silverMetal, goldMetal, platinumMetal, mithrilMetal, adamantiteMetal, preciousMetal
    ]
    
    var isMetallic: Bool {
        return Material.metals.contains(self)
    }
    
    var name: String {
        switch self {
        case .tinMetal:        return "олово"
        case .bronzeMetal:     return "бронза"
        case .copperMetal:     return "медь"
        case .ironMetal:       return "железо"
        case .steelMetal:      return "сталь"
        case .otherMetal:      return "металл"
        case .silverMetal:     return "серебро"
        case .goldMetal:       return "золото"
        case .platinumMetal:   return "платина"
        case .mithrilMetal:    return "мифрил"
        case .adamantiteMetal: return "адамантит"
        case .preciousMetal:   return "драгоценный металл"
        case .crystal:         return "кристалл"
        case .ice:             return "лед"
        case .thinWood:        return "тонкое дерево"
        case .thickWood:       return "толстое дерево"
        case .ceramic:         return "керамика"
        case .glass:           return "стекло"
        case .stone:           return "камень"
        case .softStone:       return "мягкий камень"
        case .bone:            return "кость"
        case .horn:            return "рог"
        case .chitin:          return "хитинг"
        case .plume:           return "перо"
        case .coral:           return "коралл"
        case .nacre:           return "раковина"
        case .cloth:           return "ткань"
        case .thickCloth:      return "плотная ткань"
        case .leather:         return "кожа"
        case .fineLeather:     return "тонкая кожа"
        case .hide:            return "шкура"
        case .scale:           return "чешуя"
        case .dragonScale:     return "чешуя дракона"
        case .organic:         return "органика"
        case .wax:             return "воск"
        case .parchment:       return "пергамент"
        case .paper:           return "бумага"
        case .jelly:           return "желе"
        case .liquid:          return "жидкость"
        case .gasVapour:       return "газ"
        }
    }
    
    var fragChance: (heat: Int, cold: Int, acid: Int, electricity: Int, crush: Int, hit: Int) {
        switch self {
        case .tinMetal:        return (30, 15, 48,  8, 20, 20)
        case .bronzeMetal:     return (20,  4, 48,  8, 20, 15)
        case .copperMetal:     return (20,  4, 48,  8, 20, 15)
        case .ironMetal:       return (22,  4, 60, 10, 25, 12)
        case .steelMetal:      return (15,  5, 36,  6, 15,  9)
        case .otherMetal:      return (20,  5, 40,  8, 20, 15)
        case .silverMetal:     return (10,  3, 25,  4, 10, 10)
        case .goldMetal:       return (12,  3, 25,  6, 15, 15)
        case .platinumMetal:   return (10,  3, 25,  4, 10, 10)
        case .mithrilMetal:    return ( 5,  1, 11,  2,  5,  3)
        case .adamantiteMetal: return (10,  2, 22,  4, 10,  6)
        case .preciousMetal:   return (12,  3, 25,  8, 15, 10)
        case .crystal:         return (20,  5, 35, 20, 55, 12)
        case .ice:             return (70,  1, 35, 15, 55, 15)
        case .thinWood:        return (50,  5, 40, 25, 80, 25)
        case .thickWood:       return (30,  5, 35, 35, 42, 20)
        case .ceramic:         return (10, 15,  5,  5, 72, 30)
        case .glass:           return (30, 25, 10, 40, 90, 50)
        case .stone:           return (10,  5, 10, 30, 34, 10)
        case .softStone:       return (10,  5, 25, 40, 60, 25)
        case .bone:            return (40,  5, 50, 10, 62, 18)
        case .horn:            return (20,  5, 40, 10, 30, 10)
        case .chitin:          return (40, 10, 50, 10, 45, 15)
        case .plume:           return (60,  3, 50, 10, 30, 20)
        case .coral:           return (30,  5, 25, 30, 45, 20)
        case .nacre:           return (25,  5, 40, 10, 30, 14)
        case .cloth:           return (75,  5, 55, 30,  5, 35)
        case .thickCloth:      return (50,  5, 45, 25,  5, 25)
        case .leather:         return (30,  8, 40, 22,  5, 20)
        case .fineLeather:     return (60, 12, 50, 30, 10, 30)
        case .hide:            return (45, 10, 45, 25,  5, 20)
        case .scale:           return (20,  8, 30, 15,  5, 18)
        case .dragonScale:     return ( 5,  8, 10,  8,  3, 10)
        case .organic:         return (45, 25, 65, 40,  5, 20)
        case .wax:             return (60,  5, 40, 20, 25, 20)
        case .parchment:       return (90,  5, 70, 30, 16,  5)
        case .paper:           return (95,  5, 80, 40, 20,  8)
        case .jelly:           return ( 5, 10, 10,  5,  0,  3)
        case .liquid:          return ( 1,  3,  3,  1,  0,  1)
        case .gasVapour:       return (11,  1,  1,  1,  0,  0)
        }
    }
    
    var maxCondition: Int {
        switch self {
        case .tinMetal:        return 200
        case .bronzeMetal:     return 320
        case .copperMetal:     return 320
        case .ironMetal:       return 360
        case .steelMetal:      return 480
        case .otherMetal:      return 350
        case .silverMetal:     return 460
        case .goldMetal:       return 380
        case .platinumMetal:   return 420
        case .mithrilMetal:    return 1440
        case .adamantiteMetal: return 720
        case .preciousMetal:   return 420
        case .crystal:         return 320
        case .ice:             return 300
        case .thinWood:        return 192
        case .thickWood:       return 240
        case .ceramic:         return 144
        case .glass:           return 60
        case .stone:           return 540
        case .softStone:       return 300
        case .bone:            return 220
        case .horn:            return 360
        case .chitin:          return 200
        case .plume:           return 180
        case .coral:           return 300
        case .nacre:           return 200
        case .cloth:           return 96
        case .thickCloth:      return 140
        case .leather:         return 260
        case .fineLeather:     return 156
        case .hide:            return 210
        case .scale:           return 360
        case .dragonScale:     return 600
        case .organic:         return 120
        case .wax:             return 100
        case .parchment:       return 64
        case .paper:           return 44
        case .jelly:           return 75
        case .liquid:          return 40
        case .gasVapour:       return 6
        }
    }
    
    static let aliases = ["материал", "труп.материал"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            // металлы
            1:     "олово",            //
            2:     "бронза",           // Бронза (металл)
            3:     "медь",             //
            4:     "железо",           // Железо (металл)
            5:     "сталь",            // Сталь (металл)
            // резерв
            9:     "металл",           // Прочие простые металлы
            10:    "серебро",          //
            11:    "золото",           //
            12:    "платина",          //
            13:    "мифрил",           // Мифрил (металл)
            14:    "адамантит",        // Адамантит (металл)
            15:    "драгметалл",       // Прочие драгоценные металлы или сплавы
            // резерв
            // прочие:
            20:    "кристалл",         // Кристалл
            21:    "лед",              // Лед и сходные с ним замерзжие жидксти
            22:    "тонкоедерево",     // Тонкое дерево
            23:    "толстоедерево",    // Толстое дерево
            24:    "керамика",         // Керамика
            25:    "стекло",           // Стекло
            26:    "камень",           // Камень
            27:    "мягкийкамень",     // легко крошащийся непрочный камень
            28:    "кость",            // Кость
            29:    "рог",              // Рог, слоновая кость и прочная кость
            30:    "хитин" ,           //
            31:    "перо",             // Перья птиц, или отдельное перо
            32:    "корал",            //
            33:    "раковина",         // раковина молюсков, перламутр
            34:    "ткань",            // Ткань
            35:    "плотнаяткань",     // Особо плотная ткань, войлок
            36:    "кожа",             // Кожа
            37:    "тонкаякожа",       // Тонкая кожа
            38:    "шкура",
            39:    "чешуя",
            40:    "шкурадракона",
            41:    "органика",         // Органика
            42:    "воск",
            43:    "пергамент",        // Пергамент
            44:    "бумага",           // Легкая, тонкая, но куда дороже!
            45:    "желе",             // Желеобразная, студёнистая масса
            46:    "жидкость",         // Жидкость
            47:    "газ"               // Газ
        ])
    }
}
