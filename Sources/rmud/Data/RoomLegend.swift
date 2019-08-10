struct RoomLegend {
    typealias T = RoomLegend
    
    static let defaultSymbol: Character = "?"
    static let symbols = "123456789АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЫЭЮЯ"

    var name = ""
    var symbol: Character = RoomLegend.defaultSymbol
    
    static func symbolFromIndex(_ index: Int) -> Character {
        if index >= 0 && index < T.symbols.count {
            return T.symbols[
                T.symbols.index(
                    T.symbols.startIndex, offsetBy: index)]
        }
        return "?"
    }
}
