import Foundation

public struct FieldFlags: OptionSet {
    public let rawValue: Int
    
    public static let entityId   = FieldFlags(rawValue: 1 << 0)
    public static let required   = FieldFlags(rawValue: 1 << 1) // "*"
    // Why would we want to morph it on save? Better to do this on set.
    //public static let automorph = FieldFlags(rawValue: 1 << 2) // "@"
    // TODO: use field groups instead
    //public static let newLine    = FieldFlags(rawValue: 1 << 3) // "!"
    public static let structureStart = FieldFlags(rawValue: 1 << 4)
    public static let structureAutoCreate = FieldFlags(rawValue: 1 << 4)
    public static let deprecated = FieldFlags(rawValue: 1 << 5)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
