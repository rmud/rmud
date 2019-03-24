import Foundation

enum AffectType: UInt8 {
    case armor                   = 1
    case bless                   = 3
    case blindness               = 4
    case charm                   = 7
    case chillTouch              = 8
    case continualLight          = 9
    case colorSpray              = 10
    case curse                   = 17
    case detectAlign             = 18
    case detectInvisible         = 19
    case detectMagic             = 20
    case detectPoison            = 21
    case energyDrain             = 25
    case invisible               = 29
    case poison                  = 33
    case protectionFromEvil      = 34
    case sanctuary               = 36
    case sleep                   = 38
    case strength                = 39
    case senseLife               = 44
    case holyAura                = 47
    case infravision             = 50
    case waterbreath             = 51
    case aid                     = 53
    case fly                     = 56
    case hold                    = 58
    case fistOfStone             = 61
    case rayOfEnfeeblement       = 63
    case haste                   = 65
    case stinkingСloud           = 66
    case delayDeath              = 67
    case enlarge                 = 68
    case reduce                  = 71
    case slow                    = 72
    case calm                    = 73
    case confusion               = 74
    case distanceDistortion      = 75
    case antimagicShell          = 79
    case clawUmberHulk           = 80
    case cloudkill               = 81
    case feeblemind              = 82
    case fireshield              = 83
    case improvedInvisibility    = 84
    case stoneSkin               = 86
    case spellTurning            = 94
    case globeOfInvulnerability  = 97
    case acceleratedHealing      = 104
    case detectEvil              = 109
    case detectGood              = 110
    case silence                 = 112
    case fright                  = 115
    case protectionFromGood      = 116
    case nightvision             = 119
    case protectionFromAcid      = 120
    case protectionFromCold      = 122
    case protectionFromFire      = 123
    case protectionFromLightning = 124
    case freeAction              = 129
    case shield                  = 135
    case elvenMind               = 136
    case ironBody                = 137
    case awareness               = 138
    case dimensionalAnchor       = 140
    case mirrorImage             = 152
    case passWithoutTrace        = 165
    case barkskin                = 166
    case magicalVestment         = 169
    case unholyAura              = 170
    case graniteCrag             = 172
    case catsGrace               = 173
    case cloakOfPain             = 174
    case fortify                 = 175
    case mortify                 = 176
    case frostshield             = 177
    case unquenchableHunger      = 179
    case ailment                 = 181
    case bravery                 = 182
    case giantHand               = 183
    case leprosy                 = 184
    case plague                  = 185
    case battleRage              = 189
    case wildRage                = 190
    case silveryMantle           = 191
    case handOfFate              = 194
    case fearlessness            = 196
    case blur                    = 197
    case ennui                   = 201
    case firebreathing           = 203
    
    static let aliases = ["пэффекты", "мэффекты"]

    static var definitions: Enumerations.EnumSpec.NamesByValue = [
        1: "доспех",
        3: "благословение",
        4: "слепота",
        7: "очарование",
        8: "ледяное_прикосновение",
        9: "вечный_свет",
        10: "цветные_брызги",
        17: "проклятие",
        18: "знание_наклонностей",
        19: "определение_невидимости",
        20: "определение_магии",
        21: "определение_яда",
        25: "истощение_жизни",
        29: "невидимость",
        33: "яд",
        34: "защита_от_зла",
        36: "убежище",
        38: "сон",
        39: "сила",
        44: "определение_жизни",
        47: "священная_аура",
        50: "инфравидение",
        51: "подводное_дыхание",
        53: "поддержка",
        56: "полет",
        58: "паралич",
        61: "каменный_кулак",
        63: "ослабляющий_луч",
        65: "ускорение",
        66: "едкое_облако",
        67: "порог_смерти",
        68: "увеличение",
        71: "уменьшение",
        72: "замедление",
        73: "спокойствие",
        74: "ошеломление",
        75: "сокращение_расстояний",
        79: "магический_барьер",
        80: "стальные_когти",
        81: "облако_смерти",
        82: "слабоумие",
        83: "огненный_щит",
        84: "улучшенная_невидимость",
        86: "каменная_кожа",
        94: "отражение_заклинаний",
        97: "сфера_неуязвимости",
        104: "ускоренное_восстановление",
        109: "определение_зла",
        110: "определение_добра",
        112: "молчание",
        115: "испуг",
        116: "защита_от_добра",
        119: "ночное_зрение",
        120: "защита_от_кислоты",
        122: "защита_от_холода",
        123: "защита_от_огня",
        124: "защита_от_электричества",
        129: "свобода_действий",
        135: "щит",
        136: "эльфийский_разум",
        137: "железное_тело",
        138: "внимание",
        140: "пространственный_якорь",
        152: "отражения",
        165: "проход_без_следа",
        166: "кора",
        169: "волшебное_облачение",
        170: "нечистая_аура",
        172: "гранитный_утес",
        173: "кошачья_грация",
        174: "плащ_боли",
        175: "сила_жизни",
        176: "мертвенная_длань",
        177: "щит_мороза",
        179: "неутолимый_голод",
        181: "хворь",
        182: "отвага",
        183: "рука_великана",
        184: "проказа",
        185: "чума",
        189: "ярость",           // - не готово
        190: "безумная_ярость",  // - не готово
        191: "серебряная_мантия",
        194: "рука_судьбы",
        196: "бесстрашие",
        197: "марево",
        201: "уныние",
        203: "огненное_дыхание",
    ]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: definitions)
    }
}

