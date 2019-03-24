import Foundation

// Used in socials to prevent using social on someone riding or fighting
struct SocialRestrictionFlags: OptionSet {
    typealias T = SocialRestrictionFlags

    let rawValue: UInt8
    
    static let notFighting  = T(rawValue: 1 << 0)
    static let notMounted   = T(rawValue: 1 << 1)
    
    static let aliases = ["дограничения", "цель.дограничения"]
    static let names: [Int64: String] = [
        1: "несражается",
        2: "неверхом"
    ]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: names)
    }
}

extension SocialRestrictionFlags: CustomStringConvertible {
    var description: String {
        let result = T.names
            .filter { k, v in contains(T(rawValue: 1 << (UInt8(k) - 1))) }
            .map { (k, v) in v }
            .joined(separator: ", ")
        return !result.isEmpty ? result : "нет"
    }
}
