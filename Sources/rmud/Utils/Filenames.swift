import Foundation

class Filenames
{
    static let sharedInstance = Filenames()
    
    var dataPrefix = "../rmud-data"
    var livePrefix = "../rmud-live"
    var debugPrefix = "../rmud-debug"
    var logFilename = ""
    
    // Game
    var classes: String { return makePath(dataPrefix, "game/classes") }
    var messages: String { return makePath(dataPrefix, "game/messages") }
    var socials: String { return makePath(dataPrefix, "game/socials") }
    var adverbs: String { return makePath(dataPrefix, "game/adverbs") }
    var spells: String { return makePath(dataPrefix, "game/spells") }
    var xnames: String { return makePath(dataPrefix, "game/xnames") }
    var endings: String { return makePath(dataPrefix, "game/endings") }

    // Help
    var helpPrefix: String { return makePath(dataPrefix, "help") }
    var helpPage: String { return makePath(dataPrefix, "help/screen") }
    
    // World
    var universe: String { return makePath(dataPrefix, "world/universe") }
    var worldPrefix: String { return makePath(dataPrefix, "world") }
    
    func directoryName(forAreaName areaName: String, startVnum: Int) -> String {
        let name = "\(areaPrefix(for: startVnum))_\(areaName.lowercased())"
        return makePath(worldPrefix, name)
    }
    
    func areaFilename(forAreaName areaName: String, startVnum: Int, fileExtension: String) -> String {
        let areaPath = directoryName(forAreaName: areaName, startVnum: startVnum)
        let filename = "\(areaPrefix(for: startVnum)).\(fileExtension)"
        return makePath(areaPath, filename)
    }
    
    private func areaPrefix(for startVnum: Int) -> String {
        return String(startVnum / 100).leftExpandingTo(minimumLength: 3, with: "0")

    }

    // Text
    var credits: String { return makePath(dataPrefix, "text/credits") }
    
    var handbook: String { return makePath(dataPrefix, "text/handbook") }
    
    var info: String { return makePath(dataPrefix, "text/info") }
    
    var newbie: String { return makePath(dataPrefix, "text/newbie") }
    
    var news: String { return makePath(dataPrefix, "text/news") }
    
    var immlist: String { return makePath(dataPrefix, "text/immlist") }
    
    var imotd: String { return makePath(dataPrefix, "text/imotd") }
    
    var logo: String { return makePath(dataPrefix, "text/logo") }
    
    var motd: String { return makePath(dataPrefix, "text/motd") }
    
    var policies: String { return makePath(dataPrefix, "text/policies") }
    
    // Live
    var bans: String { return makePath(livePrefix, "bans") }
    
    func board(type: Int) -> String {
        return "\(makePath(livePrefix, "board"))\(type)"
    }
    
    var bugs: String { return makePath(livePrefix, "bugs") }
    
    var die: String { return makePath(livePrefix, ".kill") }
    
    var dns: String { return makePath(livePrefix, "dns") }
    
    var downtime: String { return makePath(livePrefix, "downtime") }
    
    var emails: String { return makePath(livePrefix, "emails") }
    
    var freeRent: String { return makePath(livePrefix, "freerent") }
    
    var ideas: String { return makePath(livePrefix, "ideas") }
    
    var immlog: String { return makePath(livePrefix, "logs/immact.log") }
    
    // Deprecated, will only be read if lastgamepulse is absent
    var lastTime: String { return makePath(livePrefix, "lasttime") }
    
    var lastGamePulse: String { return makePath(livePrefix, "lastgamepulse") }
    
    var lastUid: String { return makePath(livePrefix, "players/last_uid") }
    
    var log: String {
        if !logFilename.isEmpty {
            return logFilename
        }
        return makePath(livePrefix, "logs/rmud.log")
    }
    
    var passwords: String { return makePath(livePrefix, "passwords") }
    
    var pause: String { return makePath(livePrefix, ".pause") }

    var accountsPrefix: String { return makePath(livePrefix, "accounts") }
    
    func accountFileName(forAccount account: Account) -> String {
        return makePath(accountsPrefix, "\(account.uid).acc")
    }
    
    var playersPrefix: String { return makePath(livePrefix, "players") }

    private func directoryName(forLowercasedPlayerName lowercasedPlayerName: String) -> String {
        let filename = lowercasedPlayerName
        let dirname = !filename.isEmpty ? String(filename.first!) : "other"
        return dirname
    }

    func directoryName(forPlayerName playerName: String) -> String {
        return directoryName(forLowercasedPlayerName: playerName.lowercased())
    }
    
    func playerFileName(forPlayerName playerName: String) -> String {
        let lowercasedPlayerName = playerName.lowercased()
        let dirname = directoryName(forLowercasedPlayerName: lowercasedPlayerName)
        let subPath = makePath(dirname, "\(lowercasedPlayerName).plr")
        return makePath(playersPrefix, subPath)
    }
    
    var debugMapPrefix: String { return makePath(debugPrefix, "maps" ) }
    
    func debugMapFilename(forAreaName areaName: String, startVnum: Int, fileExtension: String) -> String {
        let filename = "\(areaPrefix(for: startVnum))_\(areaName.lowercased()).\(fileExtension)"
        return makePath(debugMapPrefix, filename)
    }

    func debugMapDiggingStepsFilename(forAreaName areaName: String, startVnum: Int, fileExtension: String) -> String {
        let filename = "\(areaPrefix(for: startVnum))_\(areaName.lowercased()).\(fileExtension)"
        return makePath(debugMapPrefix, filename)
    }
    
    var areaFormat: String { return makePath(debugPrefix, "areaformat.txt") }
    
    var reboot: String { return makePath(livePrefix, ".reboot") }
    
    var stats: String { return makePath(livePrefix, "stats") }
    
    var statsOld: String { return stats + ".old" }
    
    var typos: String { return makePath(livePrefix, "typos") }
    
    var usage: String { return makePath(livePrefix, "usage") }
    
    var usageOld: String { return usage + ".old" }

    private func makePath(_ prefix: String, _ path: String) -> String {
        var result = prefix.replacingOccurrences(of: "\\", with: "/")
        if result.isEmpty || result.last! != "/" {
            result += "/"
        }
        result += path
        return result
    }
}
