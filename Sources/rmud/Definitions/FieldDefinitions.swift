import Foundation

class FieldDefinitions {
    //private var structureNames = Set<String>()
    private(set) var fieldsByLowercasedName: [String: FieldInfo] = [:]
    //private(set) public var orderedFieldNames: [String] = []
    private(set) var requiredFieldNamesLowercased: [String] = []
    
    private let enumerations: Enumerations

    init(enumerations: Enumerations) {
        self.enumerations = enumerations
    }

    func fieldInfo(byAbbreviatedFieldName name: String) -> FieldInfo? {
        let lowercased = name.lowercased()
        
        // Prefer exact match
        if let fieldInfo = fieldsByLowercasedName[lowercased] {
            return fieldInfo
        }
        
        // No luck, try abbreviations
        for (_, fieldInfo) in fieldsByLowercasedName.sorted(by: { $0.key < $1.key }) {
            // Both names are already lowercased, so do a case sensitive compare
            if lowercased.isAbbrev(of: fieldInfo.lowercasedName, caseInsensitive: false) {
                return fieldInfo
            }
        }
        return nil

    }
    
    func entityIdFieldLowercasedName() -> String? {
        for (lowercasedName, fieldInfo) in fieldsByLowercasedName {
            if fieldInfo.flags.contains(.entityId) {
                return lowercasedName
            }
        }
        return nil
    }
    
    func insert(fieldInfo: FieldInfo) throws {
        guard fieldsByLowercasedName[fieldInfo.lowercasedName] == nil else {
            throw FieldDefinitionsError(kind: .duplicateFieldDefinition(fieldInfo: fieldInfo))
        }
        fieldsByLowercasedName[fieldInfo.lowercasedName] = fieldInfo
        //orderedFieldNames.append(fieldInfo.name)
        if fieldInfo.flags.contains(.required) {
            requiredFieldNamesLowercased.append(fieldInfo.lowercasedName)
        }
        switch fieldInfo.type {
        case .enumeration, .flags:
            guard nil != enumerations.enumSpecsByAlias[fieldInfo.lowercasedName] else {
                throw FieldDefinitionsError(kind: .enumOrFlagsFieldNotFullyDefined(fieldInfo: fieldInfo))
            }
        default: break
        }
    }
    
    func insert(name: String, type: FieldType, flags: FieldFlags = [])  throws {
        let fieldInfo = FieldInfo(lowercasedName: name.lowercased(), type: type, flags: flags)
        try insert(fieldInfo: fieldInfo)
    }
    
    // Returns true if structure has not been registered before
    //private func registerStructure(name: String) -> Bool {
    //    guard !structureNames.contains(name) else { return false }
    //    structureNames.insert(name)
    //    return true
    //}
}

struct FieldDefinitionsError: Error, CustomStringConvertible {
    enum Kind: CustomStringConvertible {
        case duplicateFieldDefinition(fieldInfo: FieldInfo)
        case enumOrFlagsFieldNotFullyDefined(fieldInfo: FieldInfo)

        var description: String {
            switch self {
            case .duplicateFieldDefinition(let fieldInfo):
                return "Duplicate field definition: \(fieldInfo.lowercasedName)"
            case .enumOrFlagsFieldNotFullyDefined(let fieldInfo):
                return "Enum or flags field not fully defined: \(fieldInfo.lowercasedName)"
            }
        }
    }
    
    let kind: Kind

    var description: String {
        return kind.description
    }
    
    var localizedDescription: String {
        return description
    }
}

extension FieldDefinitionsError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}

