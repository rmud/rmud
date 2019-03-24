import Foundation

enum MudlogVerbosity: UInt8 {
    case off = 0
    case brief = 1
    case normal = 2
    case complete = 3
}

extension MudlogVerbosity: Equatable {
    static func ==(lhs: MudlogVerbosity, rhs: MudlogVerbosity) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension MudlogVerbosity: Comparable {
    static func <(lhs: MudlogVerbosity, rhs: MudlogVerbosity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

