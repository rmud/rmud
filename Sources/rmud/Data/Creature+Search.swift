import Foundation

extension Creature {
    // Is str a name or synonym in the appropriate grammatical case?
    // Nominative case is always checked!
    func isAbbrevOfNameOrSynonym(_ arg: String, cases: GrammaticalCases) -> Bool {
        return isPredicateOfNameOrSynonym(arg, cases: cases) { name in
            arg.isAbbrev(of: name)
        }
    }
        
    private func isPredicateOfNameOrSynonym(_ arg: String, cases: GrammaticalCases, predicate: (_ name: String) -> Bool) -> Bool {

        guard !arg.isEmpty else { return false }
        
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

        if let synonyms = mobile?.synonyms, synonyms.contains(where: predicate) {
            return true
        }
        
        return false
    }
}
