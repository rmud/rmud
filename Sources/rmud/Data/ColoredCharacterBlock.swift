import Foundation

class ColoredCharacterBlock {
    struct Cursor {
        var x = 0
        var y = 0
    }
    
    private(set) var width: Int = 0
    private(set) var height: Int = 0
    private(set) var data: [[ColoredCharacter]] = []
    
    init() {
    }
    
    init(from row: [ColoredCharacter]) {
        width = row.count
        height = 1
        data = [row]
    }
    
    init(from twoDArray: [[ColoredCharacter]]) {
        var cursor = Cursor()
        for row in twoDArray {
            printLine(&cursor, block: ColoredCharacterBlock(from: row))
        }
    }
    
    func printLine(_ cursor: inout Cursor, text: String, color: String) {
        print(&cursor, text: text, color: color)
        newLine(&cursor)
    }

    func printLine(_ cursor: inout Cursor, block: ColoredCharacterBlock) {
        print(&cursor, block: block)
        newLine(&cursor)
    }
    
    func print(_ cursor: inout Cursor, text: String, color: String) {
        printAt(x: cursor.x, y: cursor.y, text: text, color: color)
        cursor.x += text.count
    }

    func print(_ cursor: inout Cursor, block: ColoredCharacterBlock) {
        printAt(x: cursor.x, y: cursor.y, block: block)
        cursor = Cursor(
            x: cursor.x + block.width,
            y: max(cursor.y, cursor.y + block.height - 1)
        )
    }
                  
    func newLine(_ cursor: inout Cursor) {
        cursor = Cursor(x: 0, y: cursor.y + 1)
        ensureHeight(cursor.y + 1)
    }
    
    func printAt(x: Int, y: Int, text: String, color: String) {
        let textLength = text.count
        
        let requiredWidth = x + textLength
        ensureWidth(requiredWidth)
        
        let requiredHeight = y + 1
        ensureHeight(requiredHeight)
        
        var row = data[y]
        let chars = text.map { c in ColoredCharacter(c, color) }
        row.replaceSubrange(x ..< x + textLength, with: chars)
        data[y] = row
    }
    
    func printAt(x: Int, y: Int, block: ColoredCharacterBlock) {
        let requiredWidth = x + block.width
        ensureWidth(requiredWidth)
        
        let requiredHeight = y + block.height
        ensureHeight(requiredHeight)

        var srcRowIndex = 0
        for destRowIndex in y ..< y + block.height {
            var row = data[destRowIndex]
            row.replaceSubrange(x ..< x + block.width, with: block.data[srcRowIndex])
            data[destRowIndex] = row
            srcRowIndex += 1
        }
    }
    
    func appendRight(block: ColoredCharacterBlock, spacing: Int) {
        printAt(x: width + spacing, y: 0, block: block)
    }
    
    func renderedAsString(withColor: Bool) -> String {
        return data.trimmedRight().renderedAsString(withColor: withColor)
    }
    
    private func ensureWidth(_ newWidth: Int) {
        if width < newWidth {
            data = data.map { row in
                let fill = [ColoredCharacter](repeating: " ", count: newWidth - width)
                return row + fill
            }
            width = newWidth
        }
    }
    
    private func ensureHeight(_ newHeight: Int) {
        if height < newHeight {
            for _ in height ..< newHeight {
                let fill = [ColoredCharacter](repeating: " ", count: width)
                data.append(fill)
            }
            height = newHeight
        }
    }
}
