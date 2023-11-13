import Foundation

extension Character {
    static let punctuationNotAffectingCapitalization = CharacterSet(
        charactersIn: ",:;-()[]<>\""
    )
    
    var isWhitespace: Bool {
        // Terribly ineffecient, but I don't know of other way
        // to iterate Character's unicode scalars
        return String(self).unicodeScalars.contains(where: {
            CharacterSet.whitespaces.contains($0)
        })
    }
    
    var shouldCapitalizeNextLetter: Bool {
        return !String(self).unicodeScalars.contains(where: {
            Character.punctuationNotAffectingCapitalization.contains($0)
        }) && !isNumber && !isWhitespace && !isNewline
    }
}
