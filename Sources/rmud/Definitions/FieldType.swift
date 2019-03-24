import Foundation

enum FieldType {
    case number
    case constrainedNumber(ClosedRange<Int64>)
    case enumeration
    case flags
    // TODO: type-safe lists like spellsList
    case list
    // TODO: type-safe dictionaries (like vnumAndEquipmentPositionDictionary, spellAndNumberDictionary)
    case dictionary
    case line
    case longText
    case dice
}
