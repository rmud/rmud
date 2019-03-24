import Foundation

class TextFiles {
    static let sharedInstance = TextFiles()

    var newsEntriesCount = 0
    var news = "" {           // mud news
        didSet {
            countNewsEntries()
        }
    }
    var credits = ""         // game credits
    var motd = ""            // message of the day - mortals
    var imotd = ""           // message of the day - immortals
    var info = ""            // info page
    var newbie = ""          // newbie page
    var immortalsList = ""   // list of gods
    var handbook = ""        // handbook for new immortals
    var policies = ""        // policies page
    var gameLogo = ""        // заставка игры
    var help = ""            // help screen
    
    func load() throws {
        news = try load(filenames.news)
        credits = try load(filenames.credits)
        motd = try load(filenames.motd)
        imotd = try load(filenames.imotd)
        help = try load(filenames.helpPage)
        info = try load(filenames.info)
        newbie = try load(filenames.newbie)
        immortalsList = try load(filenames.immlist)
        policies = try load(filenames.policies)
        handbook = try load(filenames.handbook)
        gameLogo = try load(filenames.logo)
    }

    private func load(_ path: String) throws -> String {
        return try String(contentsOfTextFile: path).trimmingCharacters(in: CharacterSet.newlines)
    }
    
    private func countNewsEntries() {
        newsEntriesCount = news.count(where: { $0 == "*" })
    }
}
