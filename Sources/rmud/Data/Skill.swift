import Foundation

enum Skill: UInt16 {
    case backstab              = 301
    case bash                  = 302
    case hide                  = 303
    case kick                  = 304
    case pick                  = 305
    case overcome              = 306
    case rescue                = 307
    case sneak                 = 308
    case steal                 = 309
    case track                 = 310
    case swing                 = 311
    case parry                 = 312
    case disarm                = 313
    case caseSkill             = 314
    case haggle                = 315
    case dodge                 = 316
    case detect                = 317
    // 318, 319 are free to use. ideas was: ОБЕЗВРЕДИТЬ & ОБОЙТИ (обойти ловушку)
    case listen                = 320
    case doublecross           = 321
    case envenom               = 322
    case trip                  = 323
    case berserk               = 324
    case blindfight            = 325
    case prepare               = 326
    case tame                  = 327
    case orient                = 328
    case lay                   = 329
    case bandage               = 330
    case intimidate            = 331
    case maneuvre              = 332
    case encamp                = 333
    case shieldblock           = 334
    case distract              = 335
    case failedHide           = 336 // не умение, но только бит для флага
    case target                = 337
    case turn                  = 338
    case meditate              = 339
    
    // Weapon skills
    case bare                  = 381
    case piercing              = 382
    case cutting               = 383
    case twoHanded             = 384
    case pole                  = 385
    case slashing              = 386
    case crushing              = 387
    case throwing              = 388
    //case misc                  = 389
    case staves                = 390
    
    static let aliases = ["умения"]

    static var definitions: Enumerations.EnumSpec.NamesByValue = [
        301: "заколоть",
        302: "сбить",
        303: "прятаться",
        304: "пнуть",
        305: "взломать",
        306: "преодолеть",
        307: "спасти",
        308: "красться",
        309: "украсть",
        310: "выследить",
        311: "вращать",
        312: "парировать",
        313: "разоружить",
        314: "приглядеться",
        315: "торговаться",
        316: "уклониться",
        317: "найти",
        //318:    *
        //319:    *
        320: "слушать",        // - не используется
        321: "замести",
        322: "отравить",
        323: "подсечь",
        324: "берсерк",
        325: "вслепую",
        326: "разделать",
        327: "приручить",
        328: "ориентироваться",
        329: "возложить",
        330: "перевязать",
        331: "запугать",
        332: "маневрировать",
        333: "расположиться",    //
        334: "блокировать",      //
        335: "отвлечь",          //
        // 336: - не умение, флаг неудачного прятания, не использовать в файлах мира
        337: "переключиться",    // - не реализовано
        338: "изгнать",          // - не реализовано
        339: "отрешиться",       //
        //
        381: "рукопашныйбой",
        382: "колющее",
        383: "режущее",
        384: "двуручное",
        385: "древковое",
        386: "рубящее",
        387: "ударное",
        388: "стрелковое",
        //389    *                // misc - прочее
        390: "посохи"
    ]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: definitions)
    }
}
