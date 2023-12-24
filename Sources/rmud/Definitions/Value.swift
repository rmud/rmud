import Foundation

enum Value {
    // TODO: move it out of Value
    enum FormattingStyle {
        case areaFile
        case ansiOutput(creature: Creature)
    }
    
    case number(Int64)
    case enumeration(Int64)
    case flags(Int64)
    case list(Set<Int64>)
    case dictionary([Int64: Int64?])
    case line(String)
    case longText([String])
    case dice(Dice<Int64>)
    
    var string: String? {
        switch self {
        case .line(let value): return value
        default: return nil
        }
    }
    
    var stringArray: [String]? {
        switch self {
        case .longText(let value): return value
        default: return nil
        }
    }
    
    var int: Int? {
        guard let value = int64 else { return nil }
        return Int(exactly: value)
    }
    
    var uint: UInt? {
        guard let value = int64 else { return nil }
        return UInt(exactly: value)
    }

    var uint8: UInt8? {
        guard let value = int64 else { return nil }
        return UInt8(exactly: value)
    }

    var uint16: UInt16? {
        guard let value = int64 else { return nil }
        return UInt16(exactly: value)
    }

    var uint32: UInt32? {
        guard let value = int64 else { return nil }
        return UInt32(exactly: value)
    }
    
    var int8: Int8? {
        guard let value = int64 else { return nil }
        return Int8(exactly: value)
    }

    var int16: Int16? {
        guard let value = int64 else { return nil }
        return Int16(exactly: value)
    }

    var int32: Int32? {
        guard let value = int64 else { return nil }
        return Int32(exactly: value)
    }

    var int64: Int64? {
        switch self {
        case .number(let value): return value
        case .enumeration(let value): return value
        case .flags(let value): return value
        default: return nil
        }
    }
    
    var list: Set<Int64>? {
        switch self {
        case .list(let value): return value
        default: return nil
        }
    }
    
    var dictionary: [Int64: Int64?]? {
        switch self {
        case .dictionary(let value): return value
        default: return nil
        }
    }
    
    var dice: Dice<Int64>? {
        switch self {
        case .dice(let value): return value
        default: return nil
        }
    }
    
    var direction: Direction? {
        guard let directionIndex = uint8 else { return nil }
        guard let direction = Direction(rawValue: directionIndex) else {
            assertionFailure()
            return nil
        }
        return direction
    }
    
    init<T: BinaryInteger>(number: T) {
        self = .number(Int64(number))
    }

    init<T: RawRepresentable>(enumeration: T) where T.RawValue: BinaryInteger {
        self = .enumeration(Int64(enumeration.rawValue))
    }

    init<T: RawRepresentable>(flags: T) where T.RawValue: BinaryInteger {
        self = .flags(Int64(flags.rawValue))
    }

    init(list: Set<Int64>) {
        self = .list(list)
    }
    
    init<Element: BinaryInteger>(list: Set<Element>) {
        self = .list(Set(list.map { Int64($0) }))
    }
    
    init<Element: RawRepresentable>(list: Set<Element>) where Element.RawValue: BinaryInteger {
        self = .list(Set(list.map { Int64($0.rawValue) }))
    }
    
    init(dictionary: [Int64: Int64?]) {
        self = .dictionary(dictionary)
    }
    
    init<T: BinaryInteger>(dice: Dice<T>) {
        guard let dice = dice.int64Dice else {
            fatalError("UInt64 dices are not supported")
        }
        self = .dice(dice)
    }

    init<Key: RawRepresentable, Value: BinaryInteger>(dictionary: [Key: Value?]) where Key.RawValue: BinaryInteger {
        let keysAndValues: [(Int64, Int64?)] = dictionary.map {
            return (Int64($0.key.rawValue), ($0.value != nil ? Int64($0.value!) : nil))
        }
        let result = [Int64: Int64?](keysAndValues, uniquingKeysWith: { _, _ in
            // Can only happen if Key's rawValue returns non-unique values
            fatalError()
        })
        self = .dictionary(result)
    }

    init<Key: BinaryInteger, Value: BinaryInteger>(dictionary: [Key: Value?]) {
        let keysAndValues: [(Int64, Int64?)] = dictionary.map {
            return (Int64($0.key), ($0.value != nil ? Int64($0.value!) : nil))
        }
        let result = [Int64: Int64?](keysAndValues, uniquingKeysWith: { _, _ in
            // Can only happen if Key's rawValue returns non-unique values
            fatalError()
        })
        self = .dictionary(result)
    }

    init(line: String) {
        self = .line(line)
    }
    
    init(longText: [String]) {
        self = .longText(longText)
    }

    func formatted(for style: FormattingStyle, continuationIndent: Int? = nil, enumSpec: Enumerations.EnumSpec? = nil) -> String {
        return formatted(for: style,
            continuationIndent: continuationIndent != nil ? { continuationIndent! } : nil,
            enumSpec: enumSpec != nil ? { enumSpec } : nil
        )
    }
    
    func formatted(for style: FormattingStyle, continuationIndent: (()->Int)?, /* fieldInfo: ()->FieldInfo, */ enumSpec: (()->Enumerations.EnumSpec?)?) -> String {
        switch self {
        case .number(let value):
            switch style {
            case .areaFile: return String(value)
            case .ansiOutput(let creature): return "\(creature.nCyn())\(value)\(creature.nNrm())"
            }
        case .enumeration(let value):
            let result = enumSpec?()?.lowercasedNamesByValue[value]?.uppercased() ?? String(value)
            switch style {
            case .areaFile: return result
            case .ansiOutput(let creature): return "\(creature.nGrn())\(result)\(creature.nNrm())"
            }
        case .flags(let value):
            let result = (0..<64).compactMap { (bitIndex: Int64) -> String? in
                if 0 != value & (1 << bitIndex) {
                    let oneBasedBitIndex = bitIndex + 1
                    return enumSpec?()?.lowercasedNamesByValue[oneBasedBitIndex]?.uppercased() ?? String(oneBasedBitIndex)
                }
                return nil
            }.joined(separator: " ")
            switch style {
            case .areaFile: return result
            case .ansiOutput(let creature): return "\(creature.nYel())\(result)\(creature.nNrm())"
            }
        case .list(let values):
            let result = values.sorted(by: <).map{
                enumSpec?()?.lowercasedNamesByValue[$0]?.uppercased() ?? String($0)
            }.joined(separator: " ")
            switch style {
            case .areaFile: return result
            case .ansiOutput(let creature): return "\(creature.nCyn())\(result)\(creature.nNrm())"
            }
        case .dictionary(let keysAndValues):
            let result = keysAndValues.sorted(by: { $0.key < $1.key }).map { key, value in
                let key = enumSpec?()?.lowercasedNamesByValue[key]?.uppercased() ?? String(key)
                if let value = value {
                    return "\(key)=\(value)"
                } else {
                    return key
                }
            }.joined(separator: " ")
            switch style {
            case .areaFile: return result
            case .ansiOutput(let creature): return "\(creature.nCyn())\(result)\(creature.nNrm())"
            }
        case .line(let value):
            let escaped = escaping(value)
            switch style {
            case .areaFile: return escaped
            case .ansiOutput(let creature): return "\(creature.bRed())\(escaped)\(creature.nNrm())"
            }
        case .longText(let values):
            let separator: String
            if let continuationIndent {
                separator = "\n" + String(repeating: " ", count: continuationIndent())
            } else {
                separator = " "
            }
            let finalText = values.map { escaping($0) }.joined(separator: separator)
            let result = !finalText.isEmpty ? finalText : escaping("")
            switch style {
            case .areaFile: return result
            case .ansiOutput(let creature): return "\(creature.bRed())\(result)\(creature.nNrm())"
            }
        case .dice(let value):
            switch style {
            case .areaFile: return value.description
            case .ansiOutput(let creature): return value.description(for: creature)
            }
        }
    }
    
    private func escaping(_ value: String) -> String {
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
