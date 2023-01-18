import Foundation

struct MultiwordName {
    private static let notLetters: CharacterSet = .letters.inverted
    
    private var _full = ""
    var full: String {
        get { return _full }
        set {
            _full = newValue
            byWord = _full
                .components(separatedBy: Self.notLetters)
                .filter { !$0.isEmpty }
                .filter { !isFillWord($0) }
        }
    }
    
    private(set) var byWord: [String] = []
    
    var isEmpty: Bool { return full.isEmpty }
    
    init(_ full: String) {
        self.full = full
    }
}

extension MultiwordName: CustomStringConvertible {
    var description: String {
        return full
    }
}
