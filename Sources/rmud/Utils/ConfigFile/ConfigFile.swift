import Foundation

public class ConfigFile {
    // DEBUG
    static let logFields = false
    
    typealias Fields = OrderedDictionary<String, String>
    typealias Sections = OrderedDictionary<String, Fields>
    
    var flags: ConfigFileFlags
    var filename: String?
    var scanner: FastScanner?
    var sections = Sections()

    let whitespacesAndNewlines = CharacterSet.whitespacesAndNewlines
    let decimalDigits = CharacterSet.decimalDigits
    
    public var sectionNames: [String] { return sections.orderedKeys }
    public var isEmpty: Bool { return sections.isEmpty }

    public init(flags: ConfigFileFlags = .defaults) {
        self.flags = flags
    }
    
    public convenience init(fromFile filename: String, flags: ConfigFileFlags = .defaults) throws {
        self.init(flags: flags)
        try load(fromFile: filename)
    }

    public convenience init(fromString string: String, flags: ConfigFileFlags = .defaults) throws {
        self.init(flags: flags)
        try load(fromString: string)
    }

    public func load(fromFile filename: String) throws {
        self.filename = filename

        let url = URL(fileURLWithPath: filename)
        let data = try Data(contentsOf: url)
        try load(fromData: [UInt8](data))
    }

    public func load(fromData data: [UInt8]) throws {
        let scanner = FastScanner(data: data.filter { $0 != 13 }) // remove \r-s
        self.scanner = scanner
        self.sections.removeAll(keepingCapacity: true)
        
        while !scanner.isAtEnd {
            try scanNextSection()
        }
    }

    public func load(fromString string: String) throws {
        print("WARNING: ConfigFile.load(fromString) is deprecated, use load(fromData) instead")
        try load(fromData: [UInt8](string.utf8))
    }
    
    public func save(toFile filename: String, atomically: Bool = true) throws {
        var out = ""
        
        var sectionKeys = sections.orderedKeys
        if flags.contains(.sortSections) {
            sectionKeys.sort {
                $0.compare($1, options: .numeric) == .orderedAscending
            }
        }
        for sectionKey in sectionKeys {
            guard !sectionKey.contains("]") else {
                try throwError(.sectionNameShouldntContainBrackets)
            }
            if !out.isEmpty {
                out += "\n"
            }
            if sectionKey.isEmpty && sectionKey == sectionKeys.first {
                // Don't start config file with "[]"
            } else {
                out += "[\(sectionKey)]\n"
            }
            guard let fields = sections[sectionKey] else { continue }
        
            var fieldKeys = fields.orderedKeys
            if flags.contains(.sortFields) {
                fieldKeys.sort {
                    $0.compare($1, options: .numeric) == .orderedAscending
                }
            }
            
            for fieldKey in fieldKeys {
                guard let value = fields[fieldKey] else { continue }
                let name = fieldKey
                var isHeredoc = false
                
                if !value.isEmpty {
                    if let firstScalar = value.unicodeScalars.first, whitespacesAndNewlines.contains(firstScalar) {
                        isHeredoc = true
                    } else if let lastScalar = value.unicodeScalars.last, whitespacesAndNewlines.contains(lastScalar) {
                        isHeredoc = true
                    } else if value.contains("\n") {
                        isHeredoc = true
                    }
                }
                
                switch isHeredoc {
                case true:
                    out += "\(name):\n"
                    value.forEachLine { line, stop in
                        if !line.isEmpty && line.hasPrefix("$") {
                            out += "$";
                        }
                        out += "\(line)\n"
                    }
                    //if value.hasSuffix("\n") {
                    //    out += "\n"
                    //}
                    out += "$\n"
                case false:
                    out += "\(name) \(value)\n"
                }
            }
        }

        try out.write(toFile: filename, atomically: atomically, encoding: .utf8)
    }
    
    public func fieldNames(section: String = "") -> [String] {
        return sections[section]?.orderedKeys ?? []
    }
    
    private func sectionAndField(_ name: String) -> (section: String, field: String) {
        let parts = name.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        guard let field = parts.last, !field.isEmpty else {
            fatalError("Field name cannot be empty")
        }
        let section = parts.count == 2 ? parts.first! : ""
        return (section, field)
    }
    
    public func get(_ name: String) -> String? {
        let (section, field) = sectionAndField(name)
        return sections[section]?[field]
    }
    
    public func get(_ name: String) -> Int? {
        guard let value: String = get(name) else { return nil }
        return Int(value)
    }

    public func get(_ name: String) -> Int8? {
        guard let value: String = get(name) else { return nil }
        return Int8(value)
    }

    public func get(_ name: String) -> Int16? {
        guard let value: String = get(name) else { return nil }
        return Int16(value)
    }

    public func get(_ name: String) -> Int32? {
        guard let value: String = get(name) else { return nil }
        return Int32(value)
    }

    public func get(_ name: String) -> Int64? {
        guard let value: String = get(name) else { return nil }
        return Int64(value)
    }

    public func get(_ name: String) -> UInt? {
        guard let value: String = get(name) else { return nil }
        return UInt(value)
    }
    
    public func get(_ name: String) -> UInt8? {
        guard let value: String = get(name) else { return nil }
        return UInt8(value)
    }

    public func get(_ name: String) -> UInt16? {
        guard let value: String = get(name) else { return nil }
        return UInt16(value)
    }

    public func get(_ name: String) -> UInt32? {
        guard let value: String = get(name) else { return nil }
        return UInt32(value)
    }

    public func get(_ name: String) -> UInt64? {
        guard let value: String = get(name) else { return nil }
        return UInt64(value)
    }

    public func get(_ name: String) -> Bool? {
        guard let value: String = get(name) else { return nil }
        if value.lowercased() == "true" { return true }
        guard let number = Int(value) else { return false }
        return number != 0
    }

    public func get(_ name: String) -> Double? {
        guard let value: String = get(name) else { return nil }
        // Replace all commas with dots in case they ended up in config file somehow
        return Double(value.replacingOccurrences(of: ",", with: "."))
    }

    public func get(_ name: String) -> Float? {
        guard let value: String = get(name) else { return nil }
        // Replace all commas with dots in case they ended up in config file somehow
        return Float(value.replacingOccurrences(of: ",", with: "."))
    }
    
    public func get(_ name: String) -> Character? {
        guard let value: String = get(name) else { return nil }
        return value.first
    }

    private func bitIndexes(_ name: String) -> [Int]? {
        guard let value: String = get(name) else { return nil }
        
        var result = [Int]()
        
        let scanner = Scanner(string: value)
        guard scanner.skipString("(") else { return nil }
        while !scanner.skipString(")") {
            guard let word = scanner.scanCharacters(from: decimalDigits) else { return nil }
            guard let bitIndex = Int(word as String) else { return nil }
            result.append(bitIndex)

            scanner.skipString(",")
        }
        return result
    }
    
    public func get<T: OptionSet>(_ name: String) -> T? where T.RawValue: FixedWidthInteger {
        guard let indexes = bitIndexes(name) else { return nil }
        return T(oneBasedBitIndexes: indexes)
    }
    
    public func delete(section: String) {
        sections.removeValue(forKey: section)
    }
    
    public func set(_ name: String = "", _ value: String?) {
        let (section, field) = sectionAndField(name)
        if let value = value {
            let fields = sections[section] ?? Fields()
            fields[field] = value
            sections[section] = fields
        } else {
            reset(name)
        }
    }

    public func set(_ name: String, _ value: Bool?) {
        if let value = value {
            set(name, value ? "true" : "false")
        } else {
            reset(name)
        }
    }

    public func set(_ name: String, _ value: Character?) {
        if let value = value {
            set(name, String(value))
        } else {
            reset(name)
        }
    }

    public func set<T: FloatingPoint>(_ name: String, _ value: T?) where T: LosslessStringConvertible {
        if let value = value {
            let value = String(value).replacingOccurrences(of: ",", with: ".")
            set(name, value)
        } else {
            reset(name)
        }
    }

    public func set<T>(_ name: String, _ value: T?) where T: BinaryInteger {
        if let value = value {
            set(name, String(describing: value))
        } else {
            reset(name)
        }
    }
    
    // Maybe over complicated a bit: http://stackoverflow.com/questions/32102936/how-do-you-enumerate-optionsettype-in-swift-2
    public func set<T: OptionSet>(_ name: String, _ value: T?) where T.RawValue: FixedWidthInteger, T.Element == T {
        if let value = value {
            var out = "("

            let rawValue = value.rawValue
            var isFirst = true
            for index in 0 ..< 64 {
                guard (rawValue & (1 << UInt64(index))) != 0 else { continue }
                if isFirst {
                    isFirst = false
                } else {
                    out += ", "
                }
                out += String(index + 1)
            }
            out += ")"

            set(name, out)
        } else {
            reset(name)
        }
    }
    
    public func reset(_ name: String) {
        let (section, field) = sectionAndField(name)
        guard let fields = sections[section] else {
            return
        }
        if nil != fields.removeValue(forKey: field) {
            sections[section] = fields
        }
    }
    
    func scanNextSection() throws {
        guard let scanner = scanner else { return }
        
        let section: String
        if scanner.skipByte(91) { // [
            if scanner.skipByte(93) { // ]
                section = ""
            } else {
                guard let value = scanner.scanUpToByte(93) else { // ]
                    try throwError(.expectedSectionName)
                }
                section = value
                
                guard scanner.skipByte(93) else { // ]
                    try throwError(.expectedSectionEnd)
                }
            }
        } else {
            section = ""
        }
        
        if ConfigFile.logFields {
            print("[\(section)]")
        }

        let fields = Fields()
        
        while true {
            guard !scanner.isAtEnd else { break } // No more data
            
            let previousLocation = scanner.scanLocation
            guard !scanner.skipByte(91) else { // [
                scanner.scanLocation = previousLocation
                break // Empty section (which is allowed)
            }
         
            guard var field = scanner.scanUpToCharacters(from: scanner.charactersToBeSkipped) else {
                try throwError(.expectedFieldName)
            }
            
            guard !field.isEmpty else {
                try throwError(.emptyFieldName)
            }
            
            var value: String
            if field.last != ":" {
                // Normal field
                value = scanLine()?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
                
            } else {
                // Multiline field
                field = String(field[..<field.index(before: field.endIndex)])

                value = try scanMultilineField()
            }
            
            if ConfigFile.logFields {
                print("  \(field)=\(value)")
            }
            
            fields[field] = value
        }
        
        
        sections[section] = fields
    }
    
    func scanLine() -> String? {
        guard let scanner = scanner else { return "" }

        let previousCharactersToBeSkipped = scanner.charactersToBeSkipped
        scanner.charactersToBeSkipped = FastCharacterSet.empty
        defer { scanner.charactersToBeSkipped = previousCharactersToBeSkipped }
        
        // If at "\n" already, return empty string
        guard !scanner.skipByte(10) else { // \n
            return ""
        }
        
        guard let line = scanner.scanUpToByte(10) else { // \n
            return nil
        }
        scanner.skipByte(10) // \n
        return line
    }
    
    func scanMultilineField() throws -> String {
        // There should be nothing after ':'
        guard let line = scanLine() else {
            try throwError(.expectedNewlineInMultilineField)
        }
        guard line.isEmpty else {
            try throwError(.invalidCharacterInMultilineField)
        }
        
        // Read the value terminated by '$' on a newline.
        // '$$' is an escape character.
        var value = ""
        var multilineBlockTerminated = false
        var firstLine = true
        while var line = scanLine() {
            switch firstLine {
            case true: firstLine = false
            case false: value += "\n"
            }
            if line.first == "$" {
                let count = line.count
                if count == 1 {
                    multilineBlockTerminated = true
                    break
                } else if line.hasPrefix("$$") {
                    line.remove(at: line.startIndex)
                } else {
                    try throwError(.invalidEscapeSequenceInMultilineField)
                }
            }
            value += line
        }
        if !multilineBlockTerminated {
            try throwError(.unterminatedMultilineField)
        }
        if value.hasSuffix("\n") {
            value = String(value[..<value.index(before: value.endIndex)])
        }
        return value
    }

    func throwError(_ kind: ConfigFileError.ErrorKind) throws -> Never  {
        throw ConfigFileError(kind: kind, line: scanner?.line(), column: scanner?.column())
    }
}
