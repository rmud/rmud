import Foundation

public class FastScanner {
    public let data: [UInt8]
    public var scanLocation = 0
    public var charactersToBeSkipped = FastCharacterSet.whitespacesAndNewlines
    
    public var string: String {
        return String(bytes: data, encoding: .utf8) ?? ""
    }
    
    public var parsedText: String {
        guard scanLocation > 0 else { return "" }
        return String(bytes: data[..<scanLocation], encoding: .utf8) ?? ""
    }
    
    public var textToParse: String {
        guard !isAtEnd else { return "" }
        return String(bytes: data[scanLocation...], encoding: .utf8) ?? ""
    }
    
    public var isAtEnd: Bool {
        let at = offsetSkippingCharactersToSkip()
        return at >= data.count
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

    public init(data: [UInt8]) {
        self.data = data
        scanLocation = 0
    }
    
    public func scanCharacters(from: FastCharacterSet) -> String? {        var at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return nil }

        var result: [UInt8] = []
        //result.reserveCapacity(1024)
        while at < data.count {
            let byte = data[at]
            guard from.contains(byte) else { break }
            result.append(byte)
            at += 1
        }
        guard !result.isEmpty else { return nil }

        scanLocation = at
        return String(bytes: result, encoding: .utf8) ?? ""
    }

    public func scanUpToByte(_ upToByte: UInt8) -> String? {
        var at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return nil }

        var result: [UInt8] = []
        var byte: UInt8 = 0
        while at < data.count {
            byte = data[at]
            guard byte != upToByte else { break }
            result.append(byte)
            at += 1
        }
        guard !result.isEmpty && at < data.count else { return nil }
        
        scanLocation = at
        return String(bytes: result, encoding: .utf8) ?? ""
    }

    public func scanUpToCharacters(from characters: FastCharacterSet) -> String? {
        var at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return nil }
        
        var result: [UInt8] = []
        var byte: UInt8 = 0
        while at < data.count {
            byte = data[at]
            guard !characters.contains(byte) else { break }
            result.append(byte)
            at += 1
        }
        guard !result.isEmpty && characters.contains(byte) else { return nil }
        
        scanLocation = at
        return String(bytes: result, encoding: .utf8) ?? ""
    }

    public func scanUpTo(_ bytes: [UInt8]) -> String? {
        var at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return nil }

        let isAtSubsequence = { (data: [UInt8], at: Int, subSequence: [UInt8]) -> Bool in
            for (index, byte) in subSequence.enumerated() {
                let dataOffset = at + index
                guard dataOffset < data.count else { return false } // data is shorter
                guard data[dataOffset] == byte else { return false }
            }
            return true
        }
        
        var result: [UInt8] = []
        var byte: UInt8 = 0
        while at < data.count {
            byte = data[at]
            guard !isAtSubsequence(data, at, bytes) else { break }
            result.append(byte)
            at += 1
        }
        guard !result.isEmpty && at < data.count else { return nil }
        
        scanLocation = at
        return String(bytes: result, encoding: .utf8) ?? ""
    }
    
    public func scanUpTo(_ string: String) -> String? {
        let bytes = [UInt8](string.utf8)
        return scanUpTo(bytes)
    }
    
    public func scanInt64() -> Int64? {
        var at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return nil }

        // Allow '-'
        var result: [UInt8] = []
        if at < data.count {
            let byte = data[at]
            if FastCharacterSet.plusMinusCharacterSet.contains(byte) {
                result.append(byte)
                at += 1
            }
        }
        
        // Scan all decimalDigits
        let decimalDigits = FastCharacterSet.decimalDigits
        while at < data.count {
            let byte = data[at]
            guard decimalDigits.contains(byte) else { break }
            result.append(byte)
            at += 1
        }
        guard !result.isEmpty else { return nil }

        scanLocation = at
        
        result.append(0)
        var value: Int64 = 0
        result.withUnsafeBufferPointer { pointer in
            pointer.baseAddress?.withMemoryRebound(to: Int8.self, capacity: result.count) { pointer in
                value = strtoll(pointer, nil, 10)
            }
        }
        return value
    }
    
    @discardableResult
    public func skipBytes(_ bytesToSkip: [UInt8]) -> Bool {
        let at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return false }

        let to = at + bytesToSkip.count
        guard to <= data.count else { return false }
        if data[at..<to].elementsEqual(bytesToSkip) {
            scanLocation = to
            return true
        }
        return false
    }

    @discardableResult
    public func skipByte(_ byteToSkip: UInt8) -> Bool {
        let at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return false }
        
        if data[at] == byteToSkip  {
            scanLocation = at + 1
            return true
        }
        return false
    }

//    @discardableResult
//    func skipString(_ stringToSkip: String) -> Bool {
//        let bytesToSkip = [UInt8](stringToSkip.utf8)
//        return skipBytes(bytesToSkip)
//    }

    @discardableResult
    public func skipUpTo(_ bytes: [UInt8]) -> Bool {
        var at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return false }
        
        var skipped = false
        while at < data.count {
            if data.count - at < bytes.count {
                // Remaining data is shorter than data we're looking for
                break
            }
            let subsequence = data[at..<(at + bytes.count)]
            guard !subsequence.elementsEqual(bytes) else { break }
            at += 1
            skipped = true
        }
        guard skipped else { return false }
        
        scanLocation = at
        return true
    }

//    @discardableResult
//    func skipUpTo(_ string: String) -> Bool {
//        fatalError()
//        return false
//    }
    
    @discardableResult
    public func skipUpToCharacters(from: FastCharacterSet) -> Bool {
        var at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return false }

        var skipped = false
        while at < data.count {
            let byte = data[at]
            guard !from.contains(byte) else { break }
            at += 1
            skipped = true
        }
        guard skipped else { return false }
        
        scanLocation = at
        return true
    }
    
    public func peekByte() -> UInt8? {
        let at = offsetSkippingCharactersToSkip()
        guard at < data.count else { return nil }

        return data[at]
    }
    
    public func line() -> Int {
        var newLinesCount = 0
        parsedText.forEach {
            if $0 == "\n" || $0 == "\r\n" {
                newLinesCount += 1
            }
        }
        return 1 + newLinesCount
    }
    
    public func column() -> Int {
        let text = parsedText
        if let range = text.range(of: "\n", options: .backwards) {
            return text.distance(from: range.upperBound, to: text.endIndex) + 1
        }
        return parsedText.count + 1
    }
    
    public func skipping(_ characters: FastCharacterSet, closure: () throws->()) rethrows {
        let previous = charactersToBeSkipped
        defer { charactersToBeSkipped = previous }
        charactersToBeSkipped = characters
        try closure()
    }
    
    private func offsetSkippingCharactersToSkip() -> Int {
        var newLocation = scanLocation
        while newLocation < data.count && charactersToBeSkipped.contains(data[newLocation]) {
            newLocation += 1
        }
        return newLocation
    }
}
