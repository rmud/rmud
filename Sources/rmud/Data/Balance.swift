import Foundation

class Balance {
    class LevelMetadata {
        var baseExperienceToNextLevel = 0
        var levelExperience = 0
        var mobileCountOfSameLevelToKill = 0
        var experiencePerMobileOfSameLevel: Int {
            baseExperienceToNextLevel / mobileCountOfSameLevelToKill
        }
    }
    
    static let sharedInstance = Balance()
    
    var levelMetadata: [LevelMetadata] =
        (0 ... maximumMortalLevel + 1).map({ _ in LevelMetadata() })
    
    func parseInfo() {
        let linesBySection: [(section: String, lines: [String])]
        do {
            let parser = MutliSectionInfoFileParser(filename: filenames.balance)
            linesBySection = try parser.parse()
        } catch {
            logFatal("Unable to load \(filenames.balance): \(error.userFriendlyDescription)")
        }
        
        for (section, lines) in linesBySection {
            processSection(section, lines: lines)
        }
    }
    
    func mobileMaximumHitpoints(level: Int) -> Int {
        return 10 + level * 33
    }
    
    func mobileExperience(level: Int) -> Int {
        return levelMetadata[level].experiencePerMobileOfSameLevel
    }
    
    private func processSection(_ section: String, lines: [String]) {
        switch section.lowercased() {
        case "exp_until_next_level_base":
            parseExpUntilNextLevelBase(section, lines)
        case "mob_count_to_kill":
            parseMobCountToKill(section, lines)
        default:
            logFatal("Unknown section name in \(filenames.balance): \(section)")
        }
    }
    
    private func getLevelMetadata(_ section: String, _ level: Int) -> LevelMetadata {
        guard let metadata = levelMetadata[safe: level] else {
            logFatal("Invalid level \(level) in \(filenames.balance), section \"\(section)\"")
        }
        return metadata
    }
    
    private func parseExpUntilNextLevelBase(_ section: String, _ lines: [String]) {
        for (index, line) in lines.enumerated() {
            let level = index + 1
            let experienceToNextLevel = Int(line) ?? 0
            let thisLevelMetadata = getLevelMetadata(section, level)
            thisLevelMetadata.baseExperienceToNextLevel = experienceToNextLevel

            let nextLevelMetadata = getLevelMetadata(section, level + 1)
            nextLevelMetadata.levelExperience =
                thisLevelMetadata.levelExperience + experienceToNextLevel
        }
    }

    private func parseMobCountToKill(_ section: String, _ lines: [String]) {
        for (index, line) in lines.enumerated() {
            let level = index + 1
            let mobileCount = Int(line) ?? 0
            let metadata = getLevelMetadata(section, level)
            metadata.mobileCountOfSameLevelToKill = mobileCount
        }
    }
}
