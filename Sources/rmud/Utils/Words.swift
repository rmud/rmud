import Foundation

struct ObjectName {
    private static let notLetters: CharacterSet = .letters.inverted
    
    private var _full = ""
    var full: String {
        get { return _full }
        set {
            _full = newValue
            byWord = _full.components(separatedBy: Self.notLetters).filter { !$0.isEmpty }
        }
    }
    
    private(set) var byWord: [String] = []
    
    init(_ full: String) {
        self.full = full
    }
}
