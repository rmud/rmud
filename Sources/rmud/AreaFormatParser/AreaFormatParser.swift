import Foundation

let areasLog = false

class AreaFormatParser {
    typealias T = AreaFormatParser
    
    enum StructureType {
        case none
        case extended
        case base
    }
    
    var scanner: FastScanner!
    var entityStartScanLocation = 0
    //var lineUtf16Offsets = [Int]() FIXME
    let db: Db
    let definitions: Definitions
    
    var fieldDefinitions: FieldDefinitions!
    var currentLowercasedAreaName: String?
    var currentEntity: Entity!
    var currentEntityComments: [String] = []
    var animateByDefault = false
    var currentFieldInfo: FieldInfo?
    var currentLowercasedFieldName = "" // struct.name
    var currentFieldNameWithIndex = "" // struct.name[0]
    var currentStructureType: StructureType = .none
    var currentStructureName = "" // struct
    var firstFieldInStructure = false
    
    private static let areaTagFieldName = "область"
    private static let roomTagFieldName = "комната"
    private static let mobileTagFieldName = "монстр"
    private static let itemTagFieldName = "предмет"
    private static let socialTagFieldName = "действие"
    
    private static let wordCharacters = FastCharacterSet.whitespacesAndNewlines.union(FastCharacterSet(string: "/;:()[]=")).inverted
    //private static let allExceptDoubleQuote = FastCharacterSet(string: "\"").inverted
    
    static let hash: UInt8 = 35 // #
    static let colon: UInt8 = 58 // :
    static let semicolon: UInt8 = 59 // ;
    static let crLf = [UInt8]([13, 10]) // \r\n
    static let lf: UInt8 = 10 // \n
    static let equals: UInt8 = 61 // =
    static let dBig: UInt8 = 68 // D
    static let dSmall: UInt8 = 100 // d
    static let ruKBig = [UInt8]("К".utf8)
    static let ruKSmall = [UInt8]("к".utf8)
    static let plus: UInt8 = 43 // +
    static let openBrace: UInt8 = 40 // (
    static let closeBrace: UInt8 = 41 // )
    static let openMultilineComment = [UInt8]("/*".utf8)
    static let closeMultilineComment = [UInt8]("*/".utf8)
    static let doubleQuote: UInt8 = 34 // "

    public init(db: Db, definitions: Definitions) {
        self.db = db
        self.definitions = definitions
    }
    
    public func load(filename: String) throws {
        let url = URL(fileURLWithPath: filename)
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw AreaParseError(kind: .unableToLoadFile(error: error), scanner: nil)
        }
        try parse(data: [UInt8](data))
    }
    
    public func parse(data: [UInt8]) throws {
        scanner = FastScanner(data: data)

        currentLowercasedAreaName = nil
        currentEntity = nil
        currentEntityComments.removeAll()
        animateByDefault = false
        currentFieldInfo = nil
        currentLowercasedFieldName = ""
        currentFieldNameWithIndex = ""
        currentStructureType = .none
        currentStructureName = ""
        firstFieldInStructure = false
        
//        lineUtf16Offsets = findLineUtf16Offsets(text: contents)
        
        try skipComments()
        while !scanner.isAtEnd {
            try scanNextField()

            try skipComments()
        }
        
        try finalizeCurrentEntity()
        
        guard currentStructureType == .none else {
            try throwError(.unterminatedStructure)
        }
    }
    
//    private func findLineUtf16Offsets(text: String) -> [Int] {
//        var offsets = [0]
//
//        var at = 0
//        for cu in text.utf16 {
//            if cu == 10 { // \n
//                offsets.append(at + 1)
//            }
//            at += 1
//        }
//
//        return offsets
//    }
    
    private func scanNextField() throws {
        try skipComments()
        
        guard let word = scanWord() else {
            try throwError(.expectedFieldName)
        }
        let (baseStructureName, field) = structureAndFieldName(word)
        
        if !baseStructureName.isEmpty {
            // Base format style structure name encountered: struct.field
            currentStructureType = .base
            currentStructureName = baseStructureName.lowercased()
            if areasLog {
                log("--- Base structure opened: \(currentStructureName)")
            }
        }

        var isNewEntity = false
        var isArea = false
        
        currentLowercasedFieldName = field.lowercased()
        if currentStructureType == .none {
            switch currentLowercasedFieldName {
            case T.areaTagFieldName:
                try finalizeCurrentEntity()
                isNewEntity = true
                isArea = true
                fieldDefinitions = definitions.areaFields
            case T.roomTagFieldName:
                try finalizeCurrentEntity()
                isNewEntity = true
                fieldDefinitions = definitions.roomFields
            case T.mobileTagFieldName:
                try finalizeCurrentEntity()
                isNewEntity = true
                fieldDefinitions = definitions.mobileFields
                animateByDefault = true
            case T.itemTagFieldName:
                try finalizeCurrentEntity()
                isNewEntity = true
                fieldDefinitions = definitions.itemFields
            case T.socialTagFieldName:
                try finalizeCurrentEntity()
                isNewEntity = true
                fieldDefinitions = definitions.socialFields
            default:
                break
            }
            
            if isNewEntity {
                entityStartScanLocation = scanner.scanLocation
            }
        }
        
        if currentStructureType != .none {
            currentLowercasedFieldName = "\(currentStructureName).\(currentLowercasedFieldName)"
        }
        
        let requireFieldSeparator: Bool
        if try openExtendedStructure() {
            if areasLog {
                log("--- Extended structure opened: \(currentStructureName)")
            }
            requireFieldSeparator = false
        } else {
            try scanValue()
            requireFieldSeparator = true
            
            if isNewEntity {
                // Prevent overwriting old entity with same id:
                
                // At this point both type and id of new entity are available.
                // Check if entity already exists and use the old one instead.
                let replaced = replaceCurrentEntityWithOldEntity()
                if areasLog {
                    if replaced {
                        log("Appending to old entity")
                    } else {
                        log("Created a new entity")
                    }
                }
                
                if isArea {
                    // Subsequent parsed entities will be assigned
                    // to this area until another area definition
                    // is encountered
                    setCurrentAreaName()
                }
            }
        }

        if currentStructureType == .base {
            currentStructureType = .none
            currentStructureName = ""
            if areasLog {
                log("--- Base structure closed")
            }
        } else if try closeExtendedStructure() {
            if areasLog {
                log("--- Extended structure closed")
            }
        }

        if requireFieldSeparator {
            try scanner.skipping(FastCharacterSet.whitespaces) {
                try skipComments()
                guard scanner.skipByte(T.colon) ||
                    scanner.skipBytes(T.crLf) ||
                    scanner.skipByte(T.lf) ||
                    scanner.isAtEnd
                else {
                    try throwError(.expectedFieldSeparator)
                }
            }
        }
    }
    
    private func assignIndexToNewStructure(named name: String) {
        if let current = currentEntity.lastStructureIndex[name] {
            currentEntity.lastStructureIndex[name] = current + 1
        } else {
            currentEntity.lastStructureIndex[name] = 0
        }
        if areasLog {
            log("assignIndexToNewStructure: named=\(name), index=\(currentEntity.lastStructureIndex[name]!)")
        }
    }
    
    private func openExtendedStructure() throws -> Bool {
        guard currentStructureType == .none else { return false }
        
        try skipComments()
        guard scanner.skipByte(T.openBrace) else {
            return false // Not a structure
        }
        
        currentStructureType = .extended
        currentStructureName = currentLowercasedFieldName
        firstFieldInStructure = true
        
        assignIndexToNewStructure(named: currentStructureName)
        
        return true
    }

    private func closeExtendedStructure() throws -> Bool {
        guard currentStructureType == .extended else { return false }
        
        try skipComments()
        guard scanner.skipByte(T.closeBrace) else {
            return false
        }
        
        currentStructureType = .none
        currentStructureName = ""
        firstFieldInStructure = false
        return true
    }
    
    private func appendCurrentIndex(toName name: String) -> String {
        if let structureName = structureName(fromFieldName: name),
            let index = currentEntity.lastStructureIndex[structureName] {
            return appendIndex(toName: name, index: index)
        }
        return name
    }

    private func scanValue() throws {
        if fieldDefinitions == nil {
            try throwError(.unsupportedEntityType)
        }
        guard let fieldInfo = fieldDefinitions.fieldsByLowercasedName[currentLowercasedFieldName] else {
            try throwError(.unknownFieldType(fieldName: currentLowercasedFieldName))
        }
        currentFieldInfo = fieldInfo
        
        switch currentStructureType {
        case .none:
            break
        case .base:
            // For base structures, assign a new index every time
            // a structure start field is encountered.
            if fieldInfo.flags.contains(.structureStart) ||
                (fieldInfo.flags.contains(.structureAutoCreate) &&
                    nil == currentEntity.lastStructureIndex[currentStructureName]) {
                assignIndexToNewStructure(named: currentStructureName)
            }
        case .extended:
            // For extended structures, new index was assigned when
            // the structure was opened.
            if firstFieldInStructure {
                firstFieldInStructure = false
                if !fieldInfo.flags.contains(anyOf: [.structureStart, .structureAutoCreate]) {
                    try throwError(.structureCantStartFromThisField)
                }
            }
        }
        
        if let name = structureName(fromFieldName: currentLowercasedFieldName),
                let index = currentEntity.lastStructureIndex[name] {
            currentFieldNameWithIndex = appendIndex(toName: currentLowercasedFieldName, index: index)
        } else {
            currentFieldNameWithIndex = currentLowercasedFieldName
        }
        
        if fieldInfo.flags.contains(.deprecated) {
            currentEntity.isMigrationNeeded = true
        }
        
        try skipComments()
        try scanner.skipping(FastCharacterSet.whitespaces) {
            switch fieldInfo.type {
            case .number: try scanNumber()
            case .constrainedNumber(let range):
                try scanNumber(validRange: range)
            case .enumeration: try scanEnumeration()
            case .flags: try scanFlags()
            case .list: try scanList()
            case .dictionary: try scanDictionary()
            case .line: try scanLine()
            case .longText: try scanLongText()
            case .dice: try scanDice()
            //default: fatalError()
            }
            
            #if !os(Linux) && !os(Windows)
            // Coredumps on Linux
            assert(scanner.charactersToBeSkipped == FastCharacterSet.whitespaces)
            #endif
        }
    }
    
    private func findOrCreateArea(lowercasedName: String) -> AreaEntities {
        if let area = db.areaEntitiesByLowercasedName[lowercasedName.lowercased()] {
            return area
        } else {
            let area = AreaEntities()
            db.areaEntitiesByLowercasedName[lowercasedName.lowercased()] = area
            return area
        }
    }

    private func finalizeCurrentEntity() throws {
        if let entity = currentEntity {
            try verifyRequiredFieldsPresence(in: currentEntity)
            
            if !currentEntityComments.isEmpty {
                // Append collected ';' and '/* */' comments to entity's comment field
                var finalComments: [String]
                if let oldCommentsValue = currentEntity.value(named: currentFieldNameWithIndex, touch: false),
                        let oldComments = oldCommentsValue.stringArray {
                    finalComments = oldComments + currentEntityComments
                } else {
                    finalComments = currentEntityComments
                }
                let commentValue = Value.longText(finalComments)
                entity.replace(name: "комментарий", value: commentValue)
                if areasLog {
                    log("Комментарий дополнен, новое значение: \(commentValue.string ?? "")")
                }
                currentEntityComments.removeAll()
            }
            
            if let area = entity.value(named: T.areaTagFieldName, touch: false),
                case .line(let areaId) = area {
                    let area = findOrCreateArea(lowercasedName: areaId.lowercased())
                    area.areaEntity = entity
            } else if let room = entity.value(named: T.roomTagFieldName, touch: false),
                    case .number(let roomIdNumber) = room {
                let roomId = Int(roomIdNumber)
                guard let currentLowercasedAreaName = deduceCurrentLowercasedAreaName(byVnum: roomId) else {
                    try throwError(.noCurrentArea)
                }
                let area = findOrCreateArea(lowercasedName: currentLowercasedAreaName)
                area.roomEntitiesByVnum[roomId] = entity
                
            } else if let mobile = entity.value(named: T.mobileTagFieldName, touch: false),
                    case .number(let mobileIdNumber) = mobile {
                let mobileId = Int(mobileIdNumber)
                guard let currentLowercasedAreaName = deduceCurrentLowercasedAreaName(byVnum: mobileId) else {
                    try throwError(.noCurrentArea)
                }
                let area = findOrCreateArea(lowercasedName: currentLowercasedAreaName)
                area.mobileEntitiesByVnum[mobileId] = entity
            } else if let item = entity.value(named: T.itemTagFieldName, touch: false),
                    case .number(let itemIdNumber) = item {
                let itemId = Int(itemIdNumber)
                guard let currentLowercasedAreaName = deduceCurrentLowercasedAreaName(byVnum: itemId) else {
                    try throwError(.noCurrentArea)
                }
                let area = findOrCreateArea(lowercasedName: currentLowercasedAreaName)
                area.itemEntitiesByVnum[itemId] = entity
            } else if let social = entity.value(named: T.socialTagFieldName, touch: false),
                    case .line(let socialName) = social {
                db.socialsEntitiesByLowercasedName[socialName.lowercased()] = entity
            } else {
                try throwError(.unknownEntityType)
            }
            
            if areasLog {
                log("---")
            }
        }
        
        currentEntity = Entity()
        animateByDefault = false
//        currentEntity.startLine = lineAtUtf16Offset(scanner.scanLocation)
        //log("\(scanner.scanLocation): \(currentEntity.startLine)")
    }
    
    private func verifyRequiredFieldsPresence(in entity: Entity) throws {
        for requiredFieldNameLowercased in fieldDefinitions.requiredFieldNamesLowercased {
            guard entity.hasRequiredField(lowercasedName: requiredFieldNameLowercased) else {
                let scanner = FastScanner(data: self.scanner.data)
                scanner.scanLocation = entityStartScanLocation
                throw AreaParseError(kind: .requiredFieldMissing(fieldName: requiredFieldNameLowercased), scanner: scanner)
            }
        }
    }
    
    private func setCurrentAreaName() {
        guard let entity = currentEntity else {
            assertionFailure()
            return
        }
        
        guard let area = entity.value(named: T.areaTagFieldName, touch: false),
            case .line(let areaId) = area else {
                assertionFailure()
                return
        }
        
        currentLowercasedAreaName = areaId
    }
    
    private func deduceCurrentLowercasedAreaName(byVnum vnum: Int) -> String? {
        if let currentLowercasedAreaName = currentLowercasedAreaName {
            return currentLowercasedAreaName
        }
        for (areaLowercasedName, areaEntities) in db.areaEntitiesByLowercasedName {
            
            let areaEntity = areaEntities.areaEntity
            guard let firstRoom = areaEntity["комнаты.первая", 0]?.int,
                let lastRoom = areaEntity["комнаты.последняя", 0]?.int else {
                    continue
            }
            let vnumRange = firstRoom..<(lastRoom + 1)
            if vnumRange.contains(vnum) {
                return areaLowercasedName
            }
        }
        return nil
    }
    
    private func replaceCurrentEntityWithOldEntity() -> Bool {
        guard let entity = currentEntity else { return false }
        
        if let area = entity.value(named: T.areaTagFieldName, touch: false),
                case .line(let areaId) = area,
                let oldEntity = db.areaEntitiesByLowercasedName[areaId.lowercased()] {
            currentEntity = oldEntity.areaEntity

        } else if let room = entity.value(named: T.roomTagFieldName, touch: false),
                case .number(let roomIdNumber) = room,
                case let roomId = Int(roomIdNumber),
                let currentLowercasedAreaName = currentLowercasedAreaName,
                let oldEntity = db.areaEntitiesByLowercasedName[currentLowercasedAreaName]?.roomEntitiesByVnum[roomId] {
            currentEntity = oldEntity
        
        } else if let mobile = entity.value(named: T.mobileTagFieldName, touch: false),
                case .number(let mobileIdNumber) = mobile,
                case let mobileId = Int(mobileIdNumber),
                let currentLowercasedAreaName = currentLowercasedAreaName,
                let oldEntity = db.areaEntitiesByLowercasedName[currentLowercasedAreaName]?.mobileEntitiesByVnum[mobileId] {
            currentEntity = oldEntity
        
        } else if let item = entity.value(named: T.itemTagFieldName, touch: false),
                case .number(let itemIdNumber) = item,
                case let itemId = Int(itemIdNumber),
                let currentLowercasedAreaName = currentLowercasedAreaName,
                let oldEntity = db.areaEntitiesByLowercasedName[currentLowercasedAreaName]?.itemEntitiesByVnum[itemId] {
            currentEntity = oldEntity
        
        } else {
            return false
        }
        
        return true
    }

    func skipComments() throws {
        while true {
            if scanner.skipByte(T.semicolon) || scanner.skipByte(T.hash) {
                let previousCharactersToBeSkipped = scanner.charactersToBeSkipped
                scanner.charactersToBeSkipped = FastCharacterSet.empty
                defer { scanner.charactersToBeSkipped = previousCharactersToBeSkipped }
                
                // If at "\n" already, do nothing
                //guard !scanner.skipString("\n") else { continue }
                //guard !scanner.skipString("\r\n") else { continue }
                guard let b = scanner.peekByte(),
                    b != 10 && b != 13 else { continue }
                
                guard let commentText = scanner.scanUpToCharacters(from: FastCharacterSet.newlines) else {
                    // No more newlines, skip until the end of text
                    scanner.scanLocation = scanner.data.count
                    return
                }
                currentEntityComments.append(commentText.trimmingCharacters(in: .whitespaces))
                // No: parser will expect field separator
                //if !scanner.skipString("\n") {
                //    scanner.skipString("\r\n")
                //}
            }
            else if scanner.skipBytes(T.openMultilineComment) {
                guard let commentText = scanner.scanUpTo(T.closeMultilineComment) else {
                    throw AreaParseError(kind: .unterminatedComment, scanner: scanner)
                }
                self.currentEntityComments += commentText
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                scanner.skipBytes(T.closeMultilineComment)
            }
            else {
                return
            }
        }
    }
    
    // Returns nil if starting double quote is not found, throws errors otherwise
    func scanQuotedText() throws -> String? {
        var result = ""
        var expectedDoubleQuoteError = false
        scanner.skipping(FastCharacterSet.whitespacesAndNewlines) {
            if !scanner.skipByte(T.doubleQuote) {
                expectedDoubleQuoteError = true //throwError(.expectedDoubleQuote)
            }
        }
        guard !expectedDoubleQuoteError else { return nil }
        
        try scanner.skipping(FastCharacterSet.empty) {
            while true {
                if scanner.skipByte(T.doubleQuote) {
                    // End of string or escaped quote?
                    if let b = scanner.peekByte(), b == 34 { // "
                        // If a quote is immediately followed by another quote,
                        // this is an escaped quote
                        scanner.skipByte(T.doubleQuote)
                        result += "\""
                        continue
                    } else {
                        // End of string
                        break
                    }
                }
                
                guard let text = scanner.scanUpToByte(T.doubleQuote) else {
                    try throwError(.unterminatedString)
                }
                result += text
            }
        }
        return result
    }
    
    func escapeText(_ text: String) -> String {
        return text.components(separatedBy: "\"").joined(separator: "\"\"")
    }
    
    func scanWord() -> String? {
        return scanner.scanCharacters(from: T.wordCharacters)
    }
    
//    private func lineAtUtf16Offset(_ offset: Int) -> Int {
//        return lineUtf16Offsets.binarySearch { $0 < offset } /* - 1 */
//    }
    
    func throwError(_ kind: AreaParseError.Kind) throws -> Never  {
        throw AreaParseError(kind: kind, scanner: scanner)
    }
}
