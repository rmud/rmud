import Foundation

extension Item {
    // Is str a name or synonym in the appropriate grammatical case?
    // Nominative case is always checked!
    func isAbbrevOfNameOrSynonym<S: StringProtocol>(_ word: S, cases: GrammaticalCases) -> Bool {
        return isPredicateOfNameOrSynonym(word: word, cases: cases) { name in
            name.hasPrefix(word, caseInsensitive: true)
        }
    }
        
    // Is str a name or synonym in the appropriate grammatical case?
    // Nominative case is always checked!
    func isEqualToNameOrSynonym(word: String, cases: GrammaticalCases) -> Bool {
        return isPredicateOfNameOrSynonym(word: word, cases: cases) { name in
            name.isEqual(to: word, caseInsensitive: true)
        }
    }
    
    private func isPredicateOfNameOrSynonym<S: StringProtocol>(word: S, cases: GrammaticalCases, predicate: (_ name: String) -> Bool) -> Bool {

        guard !word.isEmpty else { return false }
        
        // Always check nominative case
        if nameNominative.byWord.contains(where: predicate) {
            return true
        }
        
        // Genitive case
        if cases.contains(.genitive) && nameGenitive.byWord.contains(where: predicate) {
            return true
        }
        
        // Dative case
        if cases.contains(.dative) && nameDative.byWord.contains(where: predicate) {
            return true
        }
        
        // Accusative case
        if cases.contains(.accusative) && nameAccusative.byWord.contains(where: predicate) {
            return true
        }
        
        // Instrumental case
        if cases.contains(.instrumental) && nameInstrumental.byWord.contains(where: predicate) {
            return true
        }
        
        // Prepositional case
        if cases.contains(.dative) && namePrepositional.byWord.contains(where: predicate) {
            return true
        }
        
        // Synonyms
        if synonyms.contains(where: predicate) {
            return true
        }
        
        return false
    }
}
