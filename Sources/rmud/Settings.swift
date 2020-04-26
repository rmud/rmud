import Foundation

// Most of these settings are configurable by user
// For static settings, see Constants.swift

class Settings {
    static let sharedInstance = Settings()

    let defaultPort: UInt16 = 3040

    // Configurable on commandline:
    var mudPorts: [UInt16] = []
    var accountVerificationEmail = ""
    var mailServer = ""
    var mailServerPassword = ""
    var isPwipeMode = false
    var saveAreasAfterLoad = false
    var saveFilesAtomically = true
    var transliterateLogs = false
    var fatalWarnings = false

    // If false, the game will skip resolving of domain names
    var mudDns = true

    let maxPlayers = 300 // Max descriptors available

    let websocketJsonWritingOptions: JSONEncoder.OutputFormatting = {
        if #available(OSX 10.13, *) {
            return [.prettyPrinted, .sortedKeys]
        } else {
            return [.prettyPrinted]
        }
    }()

    var debugSaveMaps = false
    var debugSaveRenderedMaps = false
    var debugSaveMapDiggingSteps = false
    let debugSaveMapDiggingStepsMaxSteps = 300
    var debugSaveRoomAlreadyExistsSteps = false
    var debugDumpEndingsDecompress = false
    var debugDumpEndingsCompress = false
    var debugLogUnusedEntityFields = false
    var debugLogSendEmailResult = false
}
