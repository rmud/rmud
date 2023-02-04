import Foundation

class Enumerations {
    class EnumSpec {
        typealias NamesByValue = [Int64: String]
        typealias ValuesByName = [String: Int64]

        init(aliases: [String], namesByValue: NamesByValue) {
            let namesByValueLower = namesByValue.mapValues{ $0.lowercased() }

            self.aliases = aliases
            self.lowercasedNamesByValue = namesByValueLower
            self.valuesByLowercasedName = Dictionary(namesByValueLower.map{ ($1, $0) }, uniquingKeysWith: { value, _ in value })
        }
        
        func value(byAbbreviatedName name: String) -> Int64? {
            let lowercased = name.lowercased()
            
            // Prefer exact match
            if let value = valuesByLowercasedName[lowercased] {
                return value
            }
            
            // No luck, try abbreviations
            for (name, value) in valuesByLowercasedName.sorted(by: { $0.key < $1.key }) {
                // Both names are already lowercased, so do a case sensitive compare
                if lowercased.isAbbrevCI(of: name, caseInsensitive: false) {
                    return value
                }
            }
            return nil
        }

        let aliases: [String]
        let valuesByLowercasedName: ValuesByName
        let lowercasedNamesByValue: NamesByValue
    }

    var enumSpecsByAlias: [String: EnumSpec] = [:]
    var enumSpecs: [EnumSpec] = []

    func add(aliases: [String], namesByValue: EnumSpec.NamesByValue) {
        let enumSpec = EnumSpec(aliases: aliases.map{ $0.lowercased() }, namesByValue: namesByValue)

        enumSpecs.append(enumSpec)
        for alias in enumSpec.aliases {
            enumSpecsByAlias[alias] = enumSpec
        }
    }
}
