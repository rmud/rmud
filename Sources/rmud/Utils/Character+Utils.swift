import Foundation

extension Character {
    var isWhitespace: Bool {
        // Terribly ineffecient, but I don't know of other way
        // to iterate Character's unicode scalars
        return String(self).unicodeScalars.contains(where: {
            CharacterSet.whitespaces.contains($0)
        })
    }
}
