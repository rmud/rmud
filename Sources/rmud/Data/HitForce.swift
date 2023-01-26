import Foundation

enum HitForce {
    case noDamage
    case bruise
    case barely
    case wound
    case woundHard
    case woundVeryHard
    case woundExtremelyHard
    case massacre
    case annihilate
    case obliterate
    
    init(damage: Int) {
        if damage <= 0 {
            self = .noDamage
        } else if damage <= 2 {
            self = .bruise
        } else if damage <= 4 {
            self = .barely
        } else if damage <= 6 {
            self = .wound
        } else if damage <= 10 {
            self = .woundHard
        } else if damage <= 15 {
            self = .woundVeryHard
        } else if damage <= 20 {
            self = .woundExtremelyHard
        } else if damage <= 30 {
            self = .massacre
        } else if damage <= 50 {
            self = .annihilate
        } else {
            self = .obliterate
        }
    }

    var attacker: String {
        switch self {
        case .noDamage: return "Вы попытались &1 2в, но не нанесли вреда."
        case .bruise: return "Вы оцарапали 2в, &2 2(его,ее,его,их)."
        case .barely: return "Вы слегка задели 2в, &2 2(его,ее,его,их)."
        case .wound: return "Вы легко ранили 2в, &2 2(его,ее,его,их)."
        case .woundHard: return "Вы ранили 2в, &2 2(его,ее,его,их)."
        case .woundVeryHard: return "Вы тяжело ранили 2в, &2 2(его,ее,его,их)."
        case .woundExtremelyHard: return "Вы смертельно ранили 2в, &2 2(его,ее,его,их)."
        case .massacre: return "Вы ПОКАЛЕЧИЛИ 2в, &2 2(его,ее,его,их)."
        case .annihilate: return "Вы УНИЧТОЖИЛИ 2в, &2 2(его,ее,его,их)."
        case .obliterate: return "Вы ОБРАТИЛИ 2в В ПРАХ, &2 2(его,ее,его,их)."
        }
    }
    
    var victim: String {
        switch self {
        case .noDamage: return "1и попытал1(ся,ась,ось,ись) &1 ВАС, но не нанес1(ла,ло,ли) вреда."
        case .bruise: return "1и оцарапал1(,а,о,и) ВАС, &2."
        case .barely: return "1и слегка задел1(,а,о,и) ВАС, &2."
        case .wound: return "1и легко ранил1(,а,о,и) ВАС, &2."
        case .woundHard: return "1и ранил1(,а,о,и) ВАС, &2."
        case .woundVeryHard: return "1и тяжело ранил1(,а,о,и) ВАС, &2."
        case .woundExtremelyHard: return "1и смертельно ранил1(,а,о,и) ВАС, &2."
        case .massacre: return "1и ПОКАЛЕЧИЛ1(,А,О,И) ВАС, &2."
        case .annihilate: return "1и УНИЧТОЖИЛ1(,А,О,И) ВАС, &2."
        case .obliterate: return "1и ОБРАТИЛ1(,А,О,И) ВАС В ПРАХ, &2."
        }
    }

    var room: String {
        switch self {
        case .noDamage: return "1и попытал1(ся,ась,ось,ись) &1 2в, но не нанес1(,ла,ло,ли) вреда."
        case .bruise: return "1и оцарапал1(,а,о,и) 2в, &2 2(его,ее,его,их)."
        case .barely: return "1и слегка задел1(,а,о,и) 2в, &2 2(его,ее,его,их)."
        case .wound: return "1и легко ранил1(,а,о,и) 2в, &2 2(его,ее,его,их)."
        case .woundHard: return "1и ранил1(,а,о,и) 2в, &2 2(его,ее,его,их)."
        case .woundVeryHard: return "1и тяжело ранил1(,а,о,и) 2в, &2 2(его,ее,его,их)."
        case .woundExtremelyHard: return "1и смертельно ранил1(,а,о,и) 2в, &2 2(его,ее,его,их)."
        case .massacre: return "1и ПОКАЛЕЧИЛ1(,А,О,И) 2в, &2 2(его,ее,его,их)."
        case .annihilate: return "1и УНИЧТОЖИЛ1(,А,О,И) 2в, &2 2(его,ее,его,их)."
        case .obliterate: return "1и ОБРАТИЛ1(,А,О,И) 2в В ПРАХ, &2 2(его,ее,его,их)."
        }
    }
    
}
