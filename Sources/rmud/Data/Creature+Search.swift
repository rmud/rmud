import Foundation

extension Creature {
    // Is str a name or synonym in the appropriate grammatical case?
    // Nominative case is always checked!
    func isAbbrevOfNameOrSynonym(_ arg: String, cases: GrammaticalCases) -> Bool {
        
        guard !arg.isEmpty else { return false }
        
        // Always check nominative case
        if nameNominative.hasPrefix(arg, caseInsensitive: true) {
            return true
        }
        
        // Genitive case
        if cases.contains(.genitive) && nameGenitive.hasPrefix(arg, caseInsensitive: true) {
            return true
        }
        
        // Dative case
        if cases.contains(.dative) && nameDative.hasPrefix(arg, caseInsensitive: true) {
            return true
        }
        
        // Accusative case
        if cases.contains(.accusative) && nameAccusative.hasPrefix(arg, caseInsensitive: true) {
            return true
        }
        
        // Instrumental case
        if cases.contains(.instrumental) && nameInstrumental.hasPrefix(arg, caseInsensitive: true) {
            return true
        }
        
        // Prepositional case
        if cases.contains(.dative) && namePrepositional.hasPrefix(arg, caseInsensitive: true) {
            return true
        }
        
        // Synonyms
        if let synonyms = mobile?.synonyms {
            for synonym in synonyms {
                if synonym.hasPrefix(arg, caseInsensitive: true) {
                    return true
                }
            }
        }
        
        return false
    }

    // Is str a name or synonym in the appropriate grammatical case?
    // Nominative case is always checked!
    func isEqualToNameOrSynonym(_ arg: String, cases: GrammaticalCases) -> Bool {
        
        guard !arg.isEmpty else { return false }
        
        // Always check nominative case
        if nameNominative.isEqual(to: arg, caseInsensitive: true) {
            return true
        }
        
        // Genitive case
        if cases.contains(.genitive) && nameGenitive.isEqual(to: arg, caseInsensitive: true) {
            return true
        }
        
        // Dative case
        if cases.contains(.dative) && nameDative.isEqual(to: arg, caseInsensitive: true) {
            return true
        }
        
        // Accusative case
        if cases.contains(.accusative) && nameAccusative.isEqual(to: arg, caseInsensitive: true) {
            return true
        }
        
        // Instrumental case
        if cases.contains(.instrumental) && nameInstrumental.isEqual(to: arg, caseInsensitive: true) {
            return true
        }
        
        // Prepositional case
        if cases.contains(.dative) && namePrepositional.isEqual(to: arg, caseInsensitive: true) {
            return true
        }
        
        // Synonyms
        if let synonyms = mobile?.synonyms {
            for synonym in synonyms {
                if synonym.isEqual(to: arg, caseInsensitive: true) {
                    return true
                }
            }
        }
        
        return false
    }
}
