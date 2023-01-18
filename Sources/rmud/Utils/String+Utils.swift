import Foundation

extension String {
    func leftExpandingTo(minimumLength: Int, with padString: String = " ", startingAt: Int = 0) -> String {
        if count < minimumLength {
            return "".padding(toLength: minimumLength - count, withPad: padString, startingAt: startingAt) + self
        }
        return self
    }
    
    func rightExpandingTo(minimumLength: Int, with padString: String = " ", startingAt: Int = 0) -> String {
        if count < minimumLength {
            return padding(toLength: minimumLength, withPad: padString, startingAt: startingAt)
        }
        return self
    }
    
    public func isAbbrev(of string: String, caseInsensitive: Bool = true) -> Bool {
        guard !string.isEmpty else { return false }
        
        let isAbbreviated = !hasSuffix("!")
        if isAbbreviated {
            return string.hasPrefix(self, caseInsensitive: caseInsensitive)
        } else {
            return string.isEqual(to: self.dropLast(1), caseInsensitive: caseInsensitive)
        }
    }


    public func isAbbrev(ofOneOf strings: [String], caseInsensitive: Bool = true) -> Bool {
        guard !isEmpty else { return false }
        return strings.contains { string in
            isAbbrev(of: string, caseInsensitive: caseInsensitive)
        }
    }
    
    public func slice(from: String, to: String) -> (String.Index, String.Index, String)? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                (substringFrom, substringTo, String(self[substringFrom..<substringTo]))
            }
        }
    }

    public func forEachLine(handler: (_ line: String, _ stop: inout Bool) throws ->()) rethrows {
        let lines = replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
        var stop = false
        for line in lines {
            try handler(line, &stop)
            if stop {
                return
            }
        }
    }

    public func forEachLine(handler: (_ index: Int, _ line: String, _ stop: inout Bool) throws ->()) rethrows {
        var index = 0
        try forEachLine { line, stop in
            try handler(index, line, &stop)
            index += 1
        }
    }

    public func hasPrefix<S: StringProtocol>(_ prefix: S, caseInsensitive: Bool) -> Bool {
        if caseInsensitive {
            guard !prefix.isEmpty else { return true }
            return nil != range(of: prefix,
                                options: [.caseInsensitive, .anchored])
        }
        return hasPrefix(prefix)
    }

    public func hasPrefix(oneOf prefixes: [String], caseInsensitive: Bool) -> Bool {
        for prefix in prefixes {
            if hasPrefix(prefix, caseInsensitive: caseInsensitive) {
                return true
            }
        }
        return false
    }

    public func isPrefix(of string: String, caseInsensitive: Bool = false) -> Bool {
        return string.hasPrefix(self, caseInsensitive: caseInsensitive)
    }
    
    public func isPrefix(ofOneOf strings: [String], caseInsensitive: Bool = false) -> Bool {
        for item in strings {
            if isPrefix(of: item, caseInsensitive: caseInsensitive) {
                return true
            }
        }
        return false
    }

    public func isEqual<S: StringProtocol>(to string: S, caseInsensitive: Bool = false) -> Bool {
        switch caseInsensitive {
        case false: return self == string
        case true: return caseInsensitiveCompare(string) == .orderedSame
        }
    }
    
    public func isEqual(toOneOf strings: [String], caseInsensitive: Bool = false) -> Bool {
        for item in strings {
            if isEqual(to: item, caseInsensitive: caseInsensitive) {
                return true
            }
        }
        return false
    }

    public func droppingPrefix(count: Int = 1) -> Substring {
        let from = index(startIndex, offsetBy: count)
        return self[from...]
    }
    
    public func droppingSuffix(count: Int = 1) -> Substring {
        let to = index(endIndex, offsetBy: -count)
        return self[..<to]
    }
    
    public func capitalizingFirstLetter() -> String {
        let first = String(prefix(1)).capitalized
        let other = String(dropFirst())
        return first + other
    }
    
    public mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
