import Foundation

struct ConfigFileError: Error, CustomStringConvertible {
    enum ErrorKind: CustomStringConvertible {
        //case expectedSectionStart
        case expectedSectionName
        case expectedSectionEnd
        case expectedFieldName
        case emptyFieldName
        case expectedNewlineInMultilineField
        case invalidCharacterInMultilineField
        case invalidEscapeSequenceInMultilineField
        case unterminatedMultilineField
        case sectionNameShouldntContainBrackets
        
        var description: String {
            switch self {
            //case .expectedSectionStart: return "expected '['"
            case .expectedSectionName: return "expected section name terminated with ']'"
            case .expectedSectionEnd: return "expected ']'"
            case .expectedFieldName: return "expected field name"
            case .emptyFieldName: return "empty field name"
            case .expectedNewlineInMultilineField: return "expected newline after ':' in multiline field"
            case .invalidCharacterInMultilineField: return "invalid character after ':' in multiline field"
            case .invalidEscapeSequenceInMultilineField: return "invalid escape sequence in multiline block"
            case .unterminatedMultilineField: return "unterminated multiline field"
            case .sectionNameShouldntContainBrackets: return "section name shouldn't contain brackets"
            }
        }
    }

    let kind: ErrorKind
    let line: Int?
    let column: Int?
    
    var description: String {
        guard let line = line, let column = column else {
            return kind.description
        }
        return "[\(line):\(column)] \(kind.description)"
    }
}

extension ConfigFileError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}

