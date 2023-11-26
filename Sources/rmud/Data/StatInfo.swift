import Foundation

struct StatInfo {
    var label: String
    var value: Value
    var maxValue: Int?
    var modifier: Int?
    var enumAlias: String? // if not set, derived from label

    init(_ label: String, _ value: Value, maxValue: Int? = nil, modifier: Int? = nil, enumAlias: String? = nil) {
        self.label = label
        self.value = value
        self.maxValue = maxValue
        self.modifier = modifier
        self.enumAlias = enumAlias
    }

    init(_ label: String, _ value: String) {
        self.label = label
        self.value = .line(value)
    }

    init(_ label: String, duration: (days: UInt64, hours: UInt64)) {
        self.label = label
        self.value = .line("\(duration.days)д \(duration.hours)ч")
    }

    init<T: BinaryInteger>(_ label: String, _ value: T, maxValue: Int? = nil, modifier: Int? = nil) {
        self.label = label
        self.value = .number(Int64(clamping: value))
        self.maxValue = maxValue
        self.modifier = modifier
    }

    func description(for creature: Creature, indent: Int = 0) -> String {
        let style: Value.FormattingStyle = .ansiOutput(creature: creature)
        
        var finalIndent = 0
        if case .longText(_) = value {
            finalIndent = label.count + 1 + indent
        }
        
        var enumSpec: Enumerations.EnumSpec?
        switch value {
        case .enumeration(_), .flags(_), .dictionary(_):
            let enumAlias = enumAlias ?? label
            enumSpec = db.definitions.enumerations.enumSpecsByAlias[enumAlias]
        default:
            break
        }
        
        var formatted = value.formatted(
            for: style, continuationIndent: finalIndent, enumSpec: enumSpec
        )
        switch value {
        case .enumeration(_), .flags(_), .dictionary(_):
            formatted = formatted.lowercased()
        default:
            break
        }

        var text = "\(label) \(formatted)"
        if let maxValue {
            text += "/\(maxValue)"
        }
        if let modifier {
            if modifier > 0 {
                text += "\(creature.nGrn())+\(modifier)\(creature.nNrm())"
            } else if modifier < 0 {
                text += "\(creature.nRed())\(modifier)\(creature.nNrm())"
            }
        }
        return text
    }
}
