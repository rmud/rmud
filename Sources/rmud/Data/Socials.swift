import Foundation

class Socials {
    static let sharedInstance = Socials()
    
    var lowercasedAdverbs: Set<String> = []
    
    func load() throws {
        try loadAdverbs()
        log("  \(lowercasedAdverbs.count) adverb\(lowercasedAdverbs.count.ending("", "s", "s"))")
        
        try loadSocialPrototypes()
        let socialsCount = db.socialsEntitiesByLowercasedName.count
        log("  \(socialsCount) social\(socialsCount.ending("", "s", "s"))")
    }
    
    private func loadAdverbs() throws {
        let data = try String(contentsOfFile: filenames.adverbs, encoding: .utf8)
        data.forEachLine { line, stop in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.first! == "#" {
                return
            }
            let lowercased = trimmed.lowercased()
            lowercasedAdverbs.insert(lowercased)
        }
    }
    
    private func loadSocialPrototypes() throws {
        let parser = AreaFormatParser(db: db,
                                      definitions: db.definitions)
        do {
            try parser.load(filename: filenames.socials)
        } catch {
            log("\(filenames.socials): \(error.userFriendlyDescription)")
            exit(1)
        }
    }
}
