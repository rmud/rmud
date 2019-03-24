import Foundation

enum MobileEventId: UInt16 {
    case invalid                   = 0

    // Shop overrides
    /* TODO: Review
    case shopListNothing           = 301
    case shopBuyNoItem             = 311
    case shopBuyCost               = 312
    case shopBuyNoCash             = 313
    case shopBuyDone               = 314
    case shopBuyDont               = 315
    case shopTradeUseless          = 321
    case shopTradeType             = 322
    case shopRepairNotNeccessary   = 331
    case shopRepairLowLevel        = 332
    case shopRepairDont            = 333
    case shopRepairCost            = 334
    case shopRepairNoCash          = 335
    case shopRepairDone            = 336
    case shopEvaluateCost          = 341
    case shopSellNonEmptyLiquid    = 351
    case shopSellNonEmptyItems     = 352
    case shopSellTooMany           = 353
    case shopSellVeryBadCondition  = 354
    case shopSellDont              = 355
    case shopSellCost              = 356
    case shopSellNoCash            = 357
    case shopSellDone              = 358
    case shopSellStinks            = 359
    case shopSellRepairDont        = 360
    case shopEstimateCost          = 361
    case shopBrowseNoItem          = 362
    case shopSellUsedWand          = 363
    case shopSellLightIsOver       = 364
    */
    
    static let aliases = ["мперехват.событие"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            :
        ])
    }
}
