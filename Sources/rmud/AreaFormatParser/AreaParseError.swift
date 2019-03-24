import Foundation

struct AreaParseError: Error, CustomStringConvertible {
    enum Kind: CustomStringConvertible {
        case unableToLoadFile(error: Error)
        case unterminatedComment
        case expectedSectionStart
        case expectedSectionName
        case expectedSectionEnd
        case unsupportedSectionType
        case flagsExpected
        case invalidFieldFlags
        case duplicateFieldDefinition
        case syntaxError
        case expectedFieldName
        case unsupportedEntityType
        case unknownFieldType(fieldName: String)
        case expectedNumber
        case valueOutOfRange(validRange: ClosedRange<Int64>)
        case duplicateField
        case expectedFieldSeparator
        case expectedDoubleQuote
        case unterminatedString
        case expectedEnumerationValue
        case invalidEnumerationNumericValue(value: Int64, allowedValues: [String])
        case invalidEnumerationStringValue(value: String, allowedValues: [String])
        case duplicateValue
        case structureCantStartFromThisField
        case unterminatedStructure
        case noCurrentArea
        case vnumOutOfRange
        case unknownEntityType
        case tagShouldStartWithHash
        case invalidTagFormat
        case invalidLinkFormat
        case areaPrototypeNotFound
        case requiredFieldMissing(fieldName: String)
        
        var description: String {
            switch self {
            case .unableToLoadFile(let error):
                return "unable to load file: \(error.userFriendlyDescription)"
            case .unterminatedComment: return "unterminated comment found"
            case .expectedSectionStart: return "expected '['"
            case .expectedSectionName: return "expected section name terminated with ']'"
            case .expectedSectionEnd: return "expected ']'"
            case .unsupportedSectionType: return "unsupported section type"
            case .flagsExpected: return "flags expected"
            case .invalidFieldFlags: return "invalid field flags"
            case .duplicateFieldDefinition: return "duplicate field definition"
            case .syntaxError: return "syntax error"
            case .expectedFieldName: return "expected field name"
            case .unsupportedEntityType: return "unsupported entity type"
            case .unknownFieldType(let fieldName): return "unknown field type '\(fieldName)'"
            case .expectedNumber: return "expected number"
            case .valueOutOfRange(let validRange): return "value is out of range, valid range: \(validRange.lowerBound) ... \(validRange.upperBound)"
            case .duplicateField: return "duplicate field"
            case .expectedFieldSeparator: return "expected field separator"
            case .expectedDoubleQuote: return "expected double quote"
            case .unterminatedString: return "unterminated string"
            case .expectedEnumerationValue: return "expected enumeration value"
            case .invalidEnumerationNumericValue(let value, let allowedValues): return "invalid enumeration value \(value), allowed values: [\(allowedValues.joined(separator: ", "))]"
            case .invalidEnumerationStringValue(let value, let allowedValues): return "invalid enumeration value '\(value)', allowed values: [\(allowedValues.joined(separator: ", "))]"
            case .duplicateValue: return "duplicate value"
            case .structureCantStartFromThisField: return "structure can't start from this field"
            case .unterminatedStructure: return "unterminated structure"
            //case .noCurrentArea: return "no current area to add entity to, please specify it using 'область' field above the entity definition"
            case .noCurrentArea: return "unable to deduce area by entity's vnum, please make sure there is a corresponding 'область' entity defined in .area file"
            case .vnumOutOfRange: return "vnum out of range"
            case .unknownEntityType: return "unknown entity type"
            case .tagShouldStartWithHash: return "tag should start with hash"
            case .invalidTagFormat: return "invalid tag format: tag should contain at least one alphanumeric value or underscore"
            case .invalidLinkFormat: return "invalid link format"
            case .areaPrototypeNotFound: return "area prototype not found"
            case .requiredFieldMissing(let fieldName): return "required field missing: \(fieldName)"
            }
        }
    }
    
    let kind: Kind
    let scanner: FastScanner?

    var description: String {
        guard let scanner = scanner else {
            return kind.description
        }
        var result = "\(scanner.line()):\(scanner.column()): \(kind.description)."
        if !scanner.isAtEnd {
            result += " Offending line:\n" +
            "\(scanner.lineBeingParsed)"
        }
        return result
    }
}

extension AreaParseError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}
