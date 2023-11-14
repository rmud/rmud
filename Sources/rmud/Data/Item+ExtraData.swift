import Foundation

extension Item {
    func asLight() -> ItemExtraData.Light? { extraData() }
    func asScroll() -> ItemExtraData.Scroll? { extraData() }
    func asWand() -> ItemExtraData.Wand? { extraData() }
    func asStaff() -> ItemExtraData.Staff? { extraData() }
    func asWeapon() -> ItemExtraData.Weapon? { extraData() }
    func asTreasure() -> ItemExtraData.Treasure? { extraData() }
    func asArmor() -> ItemExtraData.Armor? { extraData() }
    func asPotion() -> ItemExtraData.Potion? { extraData() }
    func asWorn() -> ItemExtraData.Worn? { extraData() }
    func asOther() -> ItemExtraData.Other? { extraData() }
    func asContainer() -> ItemExtraData.Container? { extraData() }
    func asNote() -> ItemExtraData.Note? { extraData() }
    func asVessel() -> ItemExtraData.Vessel? { extraData() }
    func asKey() -> ItemExtraData.Key? { extraData() }
    func asFood() -> ItemExtraData.Food? { extraData() }
    func asMoney() -> ItemExtraData.Money? { extraData() }
    func asPen() -> ItemExtraData.Pen? { extraData() }
    func asBoat() -> ItemExtraData.Boat? { extraData() }
    func asFountain() -> ItemExtraData.Fountain? { extraData() }
    func asSpellbook() -> ItemExtraData.Spellbook? { extraData() }
    func asBoard() -> ItemExtraData.Board? { extraData() }
    func asReceipt() -> ItemExtraData.Receipt? { extraData() }
    func asToken() -> ItemExtraData.Token? { extraData() }
    
    func isLight() -> Bool { asLight() != nil }
    func isScroll() -> Bool { asScroll() != nil }
    func isWand() -> Bool { asWand() != nil }
    func isStaff() -> Bool { asStaff() != nil }
    func isWeapon() -> Bool { asWeapon() != nil }
    func isTreasure() -> Bool { asTreasure() != nil }
    func isArmor() -> Bool { asArmor() != nil }
    func isPotion() -> Bool { asPotion() != nil }
    func isWorn() -> Bool { asWorn() != nil }
    func isOther() -> Bool { asOther() != nil }
    func isContainer() -> Bool { asContainer() != nil }
    func isNote() -> Bool { asNote() != nil }
    func isVessel() -> Bool { asVessel() != nil }
    func isKey() -> Bool { asKey() != nil }
    func isFood() -> Bool { asFood() != nil }
    func isMoney() -> Bool { asMoney() != nil }
    func isPen() -> Bool { asPen() != nil }
    func isBoat() -> Bool { asBoat() != nil }
    func isFountain() -> Bool { asFountain() != nil }
    func isSpellbook() -> Bool { asSpellbook() != nil }
    func isBoard() -> Bool { asBoard() != nil }
    func isReceipt() -> Bool { asReceipt() != nil }
    func isToken() -> Bool { asToken() != nil }

    private func extraData<T: ItemExtraDataType>() -> T? {
        guard let data = extraDataByItemType[T.itemType] else { return nil }
        guard let casted = data as? T else {
            assertionFailure()
            return nil
        }
        return casted
    }
}
