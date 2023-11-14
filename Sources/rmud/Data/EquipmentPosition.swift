import Foundation

// Character equipment positions: used as index for char_data.equipment[]
// NOTE: Don't confuse these constants with the ITEM_ bitvectors
// which control the valid places you can wear a piece of equipment.
enum EquipmentPosition: Int8, CaseIterable {
    case light       = 0
    case fingerRight = 1
    case fingerLeft  = 2
    
    // начиная отсюда металлические предметы мешают магам колдовать
    case neck        = 3
    case neckAbout   = 4
    case body        = 5
    case head        = 6
    case face        = 7
    case legs        = 8
    case feet        = 9
    case hands       = 10
    case arms        = 11
    case shield      = 12
    case about       = 13
    case back        = 14
    case waist       = 15
    // в остальных позициях маги могут носить металлы
    case wristRight  = 16
    case wristLeft   = 17
    case ears        = 18
    
    case wield       = 19
    case hold        = 20
    case twoHand     = 21

    static let count = 22 // This must be the # of eq positions!
    
    static let wearBody: Set<EquipmentPosition> = [
        .neckAbout, .body, .head, .face, .legs, .feet, .hands, .arms, .shield, .about, .back, .waist, .wristRight, .wristLeft, .ears]
    static let nocast: Set<EquipmentPosition> = [
        .neckAbout, .body, .head, .face, .legs, .feet, .hands, .arms, .shield, .about, .back, .waist
    ]
    static let primaryWeapon: Set<EquipmentPosition> = [.wield, .twoHand]
    
    var bodypartInfo: BodypartInfo {
        //                                     name:           wearFlags:  armor:        fragChance: options:
        switch self {
        case .light:       return BodypartInfo("свет",         .take,      0,            3,          [])
        case .fingerRight: return BodypartInfo("на пальце",    .finger,    0,            1,          [])
        case .fingerLeft:  return BodypartInfo("на пальце",    .finger,    0,            1,          [])
        case .neck:        return BodypartInfo("на шее",       .neck,      0,            2,          [])
        case .neckAbout:   return BodypartInfo("вокруг шеи",   .neckAbout, Armor.neck,   4,          .mageNoMetal)
        case .body:        return BodypartInfo("на теле",      .body,      Armor.body,   8,          .mageNoMetal)
        case .head:        return BodypartInfo("на голове",    .head,      Armor.head,   5,          .mageNoMetal)
        case .face:        return BodypartInfo("на лице",      .face,      0,            4,          [])
        case .legs:        return BodypartInfo("на ногах",     .legs,      Armor.limb,   6,          .mageNoMetal)
        case .feet:        return BodypartInfo("как обувь",    .feet,      Armor.small,  3,          .mageNoMetal)
        case .hands:       return BodypartInfo("на кистях",    .hands,     Armor.small,  3,          .mageNoMetal)
        case .arms:        return BodypartInfo("на руках",     .arms,      Armor.limb,   6,          .mageNoMetal)
        case .shield:      return BodypartInfo("щит",          .shield,    Armor.shield, 12,         .mageNoMetal)
        case .about:       return BodypartInfo("вокруг тела",  .about,     0,            8,          [])
        case .back:        return BodypartInfo("за спиной",    .back,      Armor.back,   4,          .mageNoMetal)
        case .waist:       return BodypartInfo("вокруг пояса", .waist,     Armor.small,  3,          .mageNoMetal)
        case .wristRight:  return BodypartInfo("на запястье",  .wrist,     0,            2,          [])
        case .wristLeft:   return BodypartInfo("на запястье",  .wrist,     0,            2,          [])
        case .ears:        return BodypartInfo("в ушах",       .ears,      0,            1,          [])
        case .wield:       return BodypartInfo("оружие",       .wield,     0,            0,          [])
        case .hold:        return BodypartInfo("в руке",       .take,      0,            3,          [])
        case .twoHand:     return BodypartInfo("в руках",      .twoHand,   0,            0,          [])
        }
    }
    
    //TODO сделать подстановку в сообщение названия надетого предмета!
    var alreadyWearing: String {
        switch self {
        case .light: return "@1в взять в руку нельзя. Вы уже держите в руке источник света."
        case .fingerRight, .fingerLeft: return "@1в надеть нельзя. У Вас уже что-то надето на пальцах обеих рук."
        case .neck: return "@1в надеть нельзя. У Вас уже что-то надето на шее."
        case .neckAbout: return "@1в надеть нельзя. У Вас уже что-то надето вокруг шеи."
        case .body: return "@1в надеть нельзя. У Вас уже что-то надето на теле."
        case .head: return "@1в надеть нельзя. У Вас уже что-то надето на голове."
        case .face: return "@1в надеть нельзя. У Вас уже что-то надето на лице."
        case .legs: return "@1в надеть нельзя. У Вас уже что-то надето на ногах."
        case .feet: return "@1в надеть нельзя. Вы уже обуты."
        case .hands: return "@1в надеть нельзя. У Вас уже что-то надето на кистях рук."
        case .arms: return "@1в надеть нельзя. У Вас уже что-то надето на руках."
        case .shield: return "@1в нельзя пристегнуть на руку. Вы уже используете щит."
        case .about: return "@1в надеть нельзя. У Вас уже что-то надето вокруг тела."
        case .back: return "@1в надеть нельзя. У Вас уже что-то надето за спиной."
        case .waist: return "@1в надеть нельзя. У Вас уже что-то надето вокруг талии."
        case .wristRight, .wristLeft: return "@1в надеть нельзя. У Вас уже что-то надето на запястьях обеих рук."
        case .ears: return "@1в надеть нельзя. У Вас уже что-то надето в ушах."
        case .wield: return "@1т вооружиться нельзя. Вы уже вооружены оружием."
        case .hold: return "@1в взять во вторую руку нельзя. Она уже занята."
        case .twoHand: return "@1т вооружиться нельзя. Вы уже держите оружие в обеих руках."
        }
    }
    
    var wearToActor: String {
        switch self {
        case .light: return "Вы зажгли @1в и взяли @1ев в руку."
        case .fingerRight: return "Вы надели @1в на палец правой руки."
        case .fingerLeft: return "Вы надели @1в на палец левой руки."
        case .neck: return "Вы надели @1в на шею."
        case .neckAbout: return "Вы надели @1в вокруг шеи."
        case .body: return "Вы надели @1в на тело."
        case .head: return "Вы надели @1в на голову."
        case .face: return "Вы надели @1в на лицо."
        case .legs: return "Вы надели @1в на ноги."
        case .feet: return "Вы обулись в @1в."
        case .hands: return "Вы надели @1в на кисти рук."
        case .arms: return "Вы надели @1в на руки."
        case .shield: return "Вы пристегнули на руку @1в."
        case .about: return "Вы надели @1в вокруг тела."
        case .back: return "Вы закинули за спину @1в."
        case .waist: return "Вы опоясались @1т."
        case .wristRight: return "Вы надели @1в на правое запястье."
        case .wristLeft: return "Вы надели @1в на левое запястье."
        case .ears: return "Вы надели в уши @1в."
        case .wield: return "Вы вооружились @1т."
        case .hold: return "Вы взяли @1в во вторую руку."
        case .twoHand: return "Вы взяли @1в в обе руки."
        }
    }

    var unableToWearToActor: String {
        switch self {
        case .light: return "Вы не смогли зажечь @1в."
        case .fingerRight: return "Вы не смогли надеть @1в на палец правой руки."
        case .fingerLeft: return "Вы не смогли надеть @1в на палец левой руки."
        case .neck: return "Вы не смогли надеть @1в на шею."
        case .neckAbout: return "Вы не смогли надеть @1в вокруг шеи."
        case .body: return "Вы не смогли надеть @1в на тело."
        case .head: return "Вы не смогли надеть @1в на голову."
        case .face: return "Вы не смогли надеть @1в на лицо."
        case .legs: return "Вы не смогли надеть @1в на ноги."
        case .feet: return "Вы не смогли обуться в @1в."
        case .hands: return "Вы не смогли надеть @1в на кисти рук."
        case .arms: return "Вы не смогли надеть @1в на руки."
        case .shield: return "Вы не смогли пристегнуть на руку @1в."
        case .about: return "Вы не смогли надеть @1в вокруг тела."
        case .back: return "Вы не смогли закинуть за спину @1в."
        case .waist: return "Вы не смогли опоясаться @1т."
        case .wristRight: return "Вы не смогли надеть @1в на правое запястье."
        case .wristLeft: return "Вы не смогли надеть @1в на левое запястье."
        case .ears: return "Вы не смогли надеть в уши @1в."
        case .wield: return "Вы не миогли вооружиться @1т."
        case .hold: return "Вы не смогли взять @1в во вторую руку."
        case .twoHand: return "Вы не смогли взять @1в в обе руки."
        }
    }

    var wearToRoom: String {
        switch self {
        case .light: return "1*и заж1(ег,гла,гло,гли) @1в и взял1(,а,о,и) @1ев в руку."
        case .fingerRight: return "1*и надел1(,а,о,и) @1в на палец правой руки."
        case .fingerLeft: return "1*и надел1(,а,о,и) @1в на палец левой руки."
        case .neck: return "1*и надел1(,а,о,и) @1в на шею."
        case .neckAbout: return "1*и надел1(,а,о,и) @1в вокруг шеи."
        case .body: return "1*и надел1(,а,о,и) @1в на тело."
        case .head: return "1*и надел1(,а,о,и) @1в на голову."
        case .face: return "1*и надел1(,а,о,и) @1в на лицо."
        case .legs: return "1*и надел1(,а,о,и) @1в на ноги."
        case .feet: return "1*и обул1(ся,ась,ось,ись) в @1в."
        case .hands: return "1*и надел1(,а,о,и) @1в на кисти рук."
        case .arms: return "1*и надел1(,а,о,и) @1в на руки."
        case .shield: return "1*и пристегнул1(,а,о,и) на руку @1в."
        case .about: return "1*и надел1(,а,о,и) @1в вокруг тела."
        case .back: return "1*и закинул1(,а,о,и) за спину @1в."
        case .waist: return "1*и опоясал1(ся,ась,ось,ись) @1т."
        case .wristRight: return "1*и надел1(,а,о,и) @1в на правое запястье."
        case .wristLeft: return "1*и надел1(,а,о,и) @1в на левое запястье."
        case .ears: return "1*и надел1(,а,о,и) в уши @1в."
        case .wield: return "1*и вооружил1(ся,ась,ось,ись) @1т."
        case .hold: return "1*и взял1(,а,о,и) @1в во вторую руку."
        case .twoHand: return "1*и взял1(,а,о,и) @1в в обе руки."
        }
    }

    var unableToWearToRoom: String {
        switch self {
        case .light: return "1*и не смог1(,ла,ло,ли) зажечь @1в."
        case .fingerRight: return "1*и не смог1(,ла,ло,ли) надеть @1в на палец правой руки."
        case .fingerLeft: return "1*и не смог1(,ла,ло,ли) надеть @1в на палец левой руки."
        case .neck: return "1*и не смог1(,ла,ло,ли) надеть @1в на шею."
        case .neckAbout: return "1*и не смог1(,ла,ло,ли) надеть @1в вокруг шеи."
        case .body: return "1*и не смог1(,ла,ло,ли) надеть @1в на тело."
        case .head: return "1*и не смог1(,ла,ло,ли) надеть @1в на голову."
        case .face: return "1*и не смог1(,ла,ло,ли) надеть @1в на лицо."
        case .legs: return "1*и не смог1(,ла,ло,ли) надеть @1в на ноги."
        case .feet: return "1*и не смог1(,ла,ло,ли) обуться в @1в."
        case .hands: return "1*и не смог1(,ла,ло,ли) надеть @1в на кисти рук."
        case .arms: return "1*и не смог1(,ла,ло,ли) надеть @1в на руки."
        case .shield: return "1*и не смог1(,ла,ло,ли) пристегнуть на руку @1в."
        case .about: return "1*и не смог1(,ла,ло,ли) надеть @1в вокруг тела."
        case .back: return "1*и не смог1(,ла,ло,ли) закинуть за спину @1в."
        case .waist: return "1*и не смог1(,ла,ло,ли) опоясаться @1т."
        case .wristRight: return "1*и не смог1(,ла,ло,ли) надеть @1в на правое запястье."
        case .wristLeft: return "1*и не смог1(,ла,ло,ли) надеть @1в на левое запястье."
        case .ears: return "1*и не смог1(,ла,ло,ли) надеть в уши @1в."
        case .wield: return "1*и не смог1(,ла,ло,ли) вооружилться @1т."
        case .hold: return "1*и не смог1(,ла,ло,ли) взялть @1в во вторую руку."
        case .twoHand: return "1*и не смог1(,ла,ло,ли) взять @1в в обе руки."
        }
    }
}
