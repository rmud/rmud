import Foundation

extension String {
    public func wrapping(withIndent indent: String = "", aroundTextColumn column: [[ColoredCharacter]], totalWidth: Int, rightMargin: Int = 0, bottomMargin: Int = 0) -> [[ColoredCharacter]] {
        
        let columnLines: [[ColoredCharacter]] = column + Array(repeating: [], count: bottomMargin)
        let columnWidth = (columnLines.map{ $0.count }.max() ?? -rightMargin) + rightMargin
        
        let totalWidth = max(totalWidth, columnWidth)
        
        var lines = [[ColoredCharacter]]()
        
        struct CurrentLine {
            var content: [ColoredCharacter] = []
            var length = 0
            var number = 0
            mutating func append(_ string: [ColoredCharacter], length: Int?) {
                content += string
                self.length += length ?? string.count
            }
            mutating func advance() -> [ColoredCharacter] {
                defer { content = [] }
                length = 0
                number += 1
                return content
            }
        }
        
        struct CurrentWord {
            var content: [ColoredCharacter] = []
            mutating func eat(_ length: Int) -> [ColoredCharacter] {
                defer { content = Array(content.dropFirst(length)) }
                return Array(content.prefix(length))
            }
            mutating func eatAll() -> [ColoredCharacter] {
                defer { content = [] }
                return content
            }
        }
        
        var isFirstWord = true
        var currentLine = CurrentLine()
        var currentWord = CurrentWord()
        
        let wordCharacterSet = CharacterSet.whitespacesAndNewlines.inverted
        let scanner = Scanner(string: self)
        scanner.charactersToBeSkipped = CharacterSet.whitespaces
        
        while !scanner.isAtEnd {
            let firstWordInLine = currentLine.length == 0
            if firstWordInLine && currentLine.number < columnLines.count {
                let column = columnLines[currentLine.number]
                let paddedColumn = column.padding(toLength: columnWidth, withPad: " ")
                currentLine.append(paddedColumn, length: columnWidth)
            }
            
            if currentWord.content.isEmpty {
                if scanner.skipString("\n") {
                    lines.append(currentLine.advance())
                    continue
                }
                
                guard var word = scanner.scanCharacters(from: wordCharacterSet) else {
                    assert(false)
                    continue
                }
                if isFirstWord {
                    isFirstWord = false
                    if !indent.isEmpty {
                        word = indent + word
                    }
                }
                currentWord.content = [ColoredCharacter](word)
            }
            
            let wordLength = currentWord.content.count
            
            if currentLine.length + wordLength >= totalWidth {
                if firstWordInLine {
                    let remainingLength = totalWidth - currentLine.length
                    currentLine.append(currentWord.eat(remainingLength), length: remainingLength)
                }
                
                lines.append(currentLine.advance())
                continue
            }
            
            if !firstWordInLine {
                currentLine.append([ColoredCharacter](" "), length: 1)
            }
            
            currentLine.append(currentWord.eatAll(), length: wordLength)
        }
        
        if !currentWord.content.isEmpty {
            if currentLine.length == 0 && currentLine.number < columnLines.count {
                let paddedColumn = columnLines[currentLine.number].padding(toLength: columnWidth, withPad: " ")
                currentLine.append(paddedColumn, length: columnWidth)
            }
            currentLine.append(currentWord.eatAll(), length: nil)
        }
        
        if currentLine.length > 0 {
            lines.append(currentLine.advance())
        }
        
        if (currentLine.number < columnLines.count) {
            lines += columnLines[currentLine.number..<columnLines.count]
        }
        
        return lines
    }

    public func wrapping(withIndent indent: String = "", aroundTextColumn column: String = "", totalWidth: Int, rightMargin: Int = 0, bottomMargin: Int = 0) -> String {
        
        let columnLines = column.components(separatedBy: "\n") + Array(repeating: "", count: bottomMargin)
        let columnWidth = (columnLines.map{ $0.count }.max() ?? -rightMargin) + rightMargin
        
        let totalWidth = max(totalWidth, columnWidth)
        
        var lines = [String]()
        
        struct CurrentLine {
            var content = ""
            var length = 0
            var number = 0
            mutating func append(_ string: String, length: Int?) {
                content += string
                self.length += length ?? string.count
            }
            mutating func advance() -> String {
                defer { content = "" }
                length = 0
                number += 1
                return content
            }
        }
        
        struct CurrentWord {
            var content = ""
            mutating func eat(_ length: Int) -> String {
                let index = content.index(content.startIndex, offsetBy: length)
                defer { content = String(content[index..<content.endIndex]) }
                return String(content[content.startIndex..<index])
            }
            mutating func eatAll() -> String {
                defer { content = "" }
                return content
            }
        }
        
        var isFirstWord = true
        var currentLine = CurrentLine()
        var currentWord = CurrentWord()
        
        let wordCharacterSet = CharacterSet.whitespacesAndNewlines.inverted
        let scanner = Scanner(string: self)
        scanner.charactersToBeSkipped = CharacterSet.whitespaces
        
        while !scanner.isAtEnd {
            let firstWordInLine = currentLine.length == 0
            if firstWordInLine && currentLine.number < columnLines.count {
                let paddedColumn = columnLines[currentLine.number].padding(toLength: columnWidth, withPad: " ", startingAt: 0)
                currentLine.append(paddedColumn, length: columnWidth)
            }
            
            if currentWord.content.isEmpty {
                if scanner.skipString("\n") { // FIXME: CharacterSet?
                    lines.append(currentLine.advance())
                    continue
                }
                
                guard var word = scanner.scanCharacters(from: wordCharacterSet) else {
                    assert(false)
                    continue
                }
                if isFirstWord {
                    isFirstWord = false
                    if !indent.isEmpty {
                        word = indent + word
                    }
                }
                currentWord.content = word
            }
            
            let wordLength = currentWord.content.count
            
            if currentLine.length + wordLength >= totalWidth {
                if firstWordInLine {
                    let remainingLength = totalWidth - currentLine.length
                    currentLine.append(currentWord.eat(remainingLength), length: remainingLength)
                }
                
                lines.append(currentLine.advance())
                continue
            }
            
            if !firstWordInLine {
                currentLine.append(" ", length: 1)
            }
            
            currentLine.append(currentWord.eatAll(), length: wordLength)
        }
        
        if !currentWord.content.isEmpty {
            if currentLine.length == 0 && currentLine.number < columnLines.count {
                let paddedColumn = columnLines[currentLine.number].padding(toLength: columnWidth, withPad: " ", startingAt: 0)
                currentLine.append(paddedColumn, length: columnWidth)
            }
            currentLine.append(currentWord.eatAll(), length: nil)
        }
        
        if currentLine.length > 0 {
            lines.append(currentLine.advance())
        }
        
        if (currentLine.number < columnLines.count) {
            lines += columnLines[currentLine.number..<columnLines.count]
        }
        
        return lines.joined(separator: "\n")
    }
}

