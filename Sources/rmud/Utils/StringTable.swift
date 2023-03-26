import Foundation

class StringTable: CustomStringConvertible {
    enum Alignment {
        case left
        case right
    }
    
    struct Cell {
        var text: String
        var color: String?
        var alignment: Alignment
        
        init(_ text: String, _ color: String? = nil, _ alignment: Alignment = .left) {
            self.text = text
            self.color = color
            self.alignment = alignment
        }

        init<T: FixedWidthInteger>(_ value: T, _ color: String? = nil, _ alignment: Alignment = .left) {
            self.text = String(value)
            self.color = color
            self.alignment = alignment
        }
    }
    
    struct Row {
        var cells: [Cell] = []
    }
    
    var rows: [Row] = []
    private var columnWidths: [Int] = []
    private var isDirty = false
    
    var description: String {
        if isDirty {
            recalculateDimensions()
        }
        var result = ""
        for (rowIndex, row) in rows.enumerated() {
            if rowIndex != 0 {
                result += "\n"
            }
            for (columnIndex, cell) in row.cells.enumerated() {
                if columnIndex != 0 {
                    result += "  "
                }
                if let color = cell.color {
                    result += color
                }
                let expandFunction =
                    cell.alignment == .left ? cell.text.rightExpandingTo : cell.text.leftExpandingTo
                result += expandFunction(columnWidths[columnIndex], " ")
                if cell.color != nil {
                    result += Ansi.nNrm
                }
            }
        }
        return result
    }

    init() {
    }
    
    func add(row: StringTable.Row) {
        rows.append(row)
        isDirty = true
    }
    
    func add(row values: [String], colors: [String] = [], alignment: Alignment = .left) {
        let cells = Zip2WithNilPadding(values, colors).map {
            Cell($0 ?? "", $1, alignment)
        }
        let row = Row(cells: cells)
        add(row: row)
    }
    
    func add(row: String...) {
        add(row: row)
    }
    
    private func recalculateDimensions() {
        defer { isDirty = false }
        
        let columnCount = rows.map { $0.cells.count }.max() ?? 0
        columnWidths = [Int](repeating: 0, count: columnCount)
        
        for row in rows {
            for (columnIndex, cell) in row.cells.enumerated() {
                let columnWidth = cell.text.count
                if columnWidths[columnIndex] < columnWidth {
                    columnWidths[columnIndex] = columnWidth
                }
            }
        }
    }
}
