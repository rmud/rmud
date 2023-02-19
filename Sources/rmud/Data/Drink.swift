import Foundation

enum Liquid: UInt8 {
    case water = 0
    case beer = 1
    case wine = 2
    case ale = 3
    case vodka = 4
    case juice = 5
    case spirit = 6
    case slime = 7
    case milk = 8
    case tea = 9
    case coffee = 10
    case blood = 11
    case saltWater = 12

    var kind: String {
        switch self {
        case .water:     return "кристально прозрачная жидкость"
        case .beer:      return "жидкость желто-коричневого цвета"
        case .wine:      return "бесцветная жидкость с пузырьками"
        case .ale:       return "жидкость коричневатого цвета"
        case .vodka:     return "мутная жидкость"
        case .juice:     return "жидкость желто-зеленого цвета"
        case .spirit:    return "прозрачная жидкость"
        case .slime:     return "жидкость зеленого цвета"
        case .milk:      return "жидкость белого цвета"
        case .tea:       return "коричневая жидкость"
        case .coffee:    return "жидкость темно-коричневого цвета"
        case .blood:     return "жидкость кровавого цвета"
        case .saltWater: return "бесцветная жидкость"
        }
    }
    
    var instrumental: String {
        switch self {
        case .water:     return "водой"
        case .beer:      return "пивом"
        case .wine:      return "вином"
        case .ale:       return "элем"
        case .vodka:     return "водкой"
        case .juice:     return "соком"
        case .spirit:    return "спиртом"
        case .slime:     return "слизью"
        case .milk:      return "молоком"
        case .tea:       return "чаем"
        case .coffee:    return "кофе"
        case .blood:     return "кровью"
        case .saltWater: return "соленой водой"
        }
    }
    
    var instrumentalWithPreposition: String {
        return "\(instrumentalPreposition) \(instrumental)"
    }
    
    // "с водой", "со спиртом"
    var instrumentalPreposition: String {
        switch self {
        case .water:     return "с"
        case .beer:      return "с"
        case .wine:      return "с"
        case .ale:       return "с"
        case .vodka:     return "с"
        case .juice:     return "с"
        case .spirit:    return "со"
        case .slime:     return "со"
        case .milk:      return "с"
        case .tea:       return "с"
        case .coffee:    return "с"
        case .blood:     return "с"
        case .saltWater: return "с"
        }
    }
    
    static let aliases = ["жидкость", "сосуд.жидкость", "фонтан.жидкость"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0:  "вода",    // Вода
            1:  "пиво",    // Пиво
            2:  "вино",    // Вино
            3:  "эль",     // Эль
            4:  "водка",   // Водка
            5:  "сок",     // Сок
            6:  "спирт",   // Спирт
            7:  "слизь",   // Слизь
            8:  "молоко",  // Молоко
            9:  "чай",     // Чай
            10: "кофе",    // Кофе
            11: "кровь",   // Кровь
            12: "соленая", // Соленая вода
        ])
    }
}
