import Foundation

class Enumerations {
    class EnumSpec {
        typealias NamesByValue = [Int64: String]
        typealias ValuesByName = [String: Int64]

        init(aliases: [String], namesByValue: NamesByValue) {
            let namesByValueLower = namesByValue.mapValues{ $0.lowercased() }

            self.aliases = aliases
            self.namesByValue = namesByValueLower
            self.valuesByName = Dictionary(namesByValueLower.map{ ($1, $0) }, uniquingKeysWith: { value, _ in value })
        }

        let aliases: [String]
        let valuesByName: ValuesByName
        let namesByValue: NamesByValue
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
