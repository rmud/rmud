import Foundation

extension Scanner {
    public func skipping(_ characters: CharacterSet?, closure: () throws->()) rethrows {
        let previous = charactersToBeSkipped
        defer { charactersToBeSkipped = previous }
        charactersToBeSkipped = characters
        try closure()
    }
    
    public func scanWord(condition: ((String) -> Bool)? = nil) -> String? {
        var word: String?
        while true {
            guard let nextWord = scanUpToCharacters(from: .whitespaces) else {
                return nil
            }
            guard condition?(nextWord) ?? true else { continue }
            word = nextWord
            break
        }
        return word
    }
    
    @discardableResult
    public func skipInteger() -> Bool {
        return scanInteger() != nil
    }
    
    @discardableResult
    public func skipInt64() -> Bool {
        return scanInt64() != nil
    }
    
    @discardableResult
    public func skipUInt64() -> Bool {
        return scanUInt64() != nil
    }
    
    @discardableResult
    public func skipHexUInt64() -> Bool {
        return scanHexUInt64() != nil
    }
    
    @discardableResult
    public func skipHexFloat() -> Bool {
        return scanHexFloat() != nil
    }
    
    @discardableResult
    public func skipHexDouble() -> Bool {
        return scanHexDouble() != nil
    }

    @discardableResult
    public func skipString(_ string: String) -> Bool {
        #if true
        return scanString(string) != nil
        #else
        let utf16 = self.string.utf16
        let startOffset = skippingCharacters(startingAt: scanLocation, in: utf16)
        let toSkip = string.utf16
        let toSkipCount = toSkip.count
        let fromIndex = utf16.index(utf16.startIndex, offsetBy: startOffset)
        if let toIndex = utf16.index(fromIndex, offsetBy: toSkipCount, limitedBy: utf16.endIndex),
                utf16[fromIndex..<toIndex].elementsEqual(toSkip) {
            scanLocation = toIndex.encodedOffset
            return true
        }
        return false
        #endif
    }

    @discardableResult
    public func skipCharacters(from: CharacterSet) -> Bool {
        return scanCharacters(from: from) != nil
    }
    
    @discardableResult
    public func skipUpTo(_ string: String) -> Bool {
        return scanUpToString(string) != nil
    }

    @discardableResult
    public func skipUpToCharacters(from set: CharacterSet) -> Bool {
        return scanUpToCharacters(from: set) != nil
    }

    public var parsedText: Substring {
        return string[..<currentIndex]
    }

    public var textToParse: Substring {
        return string[currentIndex...]
    }
    
    public var lineBeingParsed: String {
        let targetLine = self.line()
        var currentLine = 1
        var line = ""
        line.reserveCapacity(256)
        for character in string {
            if currentLine > targetLine {
                break
            }
            
            if character == "\n" || character == "\r\n" {
                currentLine += 1
                continue
            }
            
            if currentLine == targetLine {
                line.append(character)
            }
        }
        return line
    }

    // Very slow, do not in use in loops
    public func line() -> Int {
        var newLinesCount = 0
        parsedText.forEach {
            if $0 == "\n" || $0 == "\r\n" {
                newLinesCount += 1
            }
        }
        return 1 + newLinesCount
    }
    
    // Very slow, do not in use in loops
    public func column() -> Int {
        let text = parsedText
        if let range = text.range(of: "\n", options: .backwards) {
            return text.distance(from: range.upperBound, to: text.endIndex) + 1
        }
        return parsedText.count + 1
    }

    #if fålse
    private func skippingCharacters(startingAt: Int, in utf16: String.UTF16View) -> Int {
        guard let charactersToBeSkipped = charactersToBeSkipped else { return startingAt }
        let fromIndex = utf16.index(utf16.startIndex, offsetBy: startingAt)
        var newLocation = startingAt
        for c in utf16[fromIndex...] {
            guard let scalar = UnicodeScalar(c) else { break }
            guard charactersToBeSkipped.contains(scalar) else { break }
            newLocation += 1
        }
        return newLocation
    }
    #endif
}

