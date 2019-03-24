import Foundation

struct GrammaticalCases: OptionSet {
    let rawValue: UInt8
    
    static let nominative = GrammaticalCases(rawValue: 1 << 0)
    static let genitive = GrammaticalCases(rawValue: 1 << 1)
    static let dative = GrammaticalCases(rawValue: 1 << 2)
    static let accusative = GrammaticalCases(rawValue: 1 << 3)
    static let instrumental = GrammaticalCases(rawValue: 1 << 4)
    static let prepositional = GrammaticalCases(rawValue: 1 << 5)
}
