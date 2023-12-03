import Foundation

struct Comment {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    func formatted() -> String {
        return "\(Ansi.bGra); \(text)\(Ansi.nNrm)"
    }
}
