import Foundation

class StringTable: CustomStringConvertible {
    struct Cell {
        var text: String
        var color: String
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
                if !cell.color.isEmpty {
                    result += cell.color
                }
                result += cell.text.rightExpandingTo(minimumLength: columnWidths[columnIndex])
                if !cell.color.isEmpty {
                    result += Ansi.nNrm
                }
            }
        }
        return result
    }

    init() {
    }
    
    func add(row values: [String], colors: [String] = []) {
        let cells = Zip2WithNilPadding(values, colors).map { Cell(text: $0 ?? "", color: $1 ?? "") }
        let row = Row(cells: cells)
        rows.append(row)
        isDirty = true
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
