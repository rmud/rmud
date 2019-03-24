import Foundation

class Spells {
    static let sharedInstance = Spells()

    private var spellInfoById: [Spell: SpellInfo] = [:]

    // Spells information parsing
    func parseInfo() {
        do {
            let parser = SpellsFileParser(filename: filenames.spells)
            try parser.parse()
        } catch {
            logFatal("Unable to load spells information: \(error.userFriendlyDescription)")
        }
    }
    
    func message(_ spell: Spell, _ name: String) -> String {
        return "(NOT IMPLEMENTED)"
    }
    
    func getSpellInfo(for spell: Spell) -> SpellInfo {
        if let spellInfo = spellInfoById[spell] {
            return spellInfo
        }
        let spellInfo = SpellInfo()
        spellInfoById[spell] = spellInfo
        return spellInfo
    }
}
