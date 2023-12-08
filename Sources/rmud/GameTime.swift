import Foundation

class GameTime {
    static let sharedInstance = GameTime()
    
    var gamePulse: UInt64 = 0
    var seconds: UInt64 { return gamePulse / 10 }
    
    func pulsesSince(gamePulse: UInt64) -> UInt64 {
        return self.gamePulse - gamePulse
    }
    
    static func pulses(inSeconds seconds: UInt64) -> UInt64 {
        return seconds * 10
    }
    
    static func tics(fromPulses pulses: UInt64) -> UInt64 {
        return pulses / 600
    }
    
    func loadFromDisk() throws {
        let text: String
        var usedLasttime = false
        do {
            text = try String(contentsOfFile: filenames.lastGamePulse, encoding: .utf8).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).components(separatedBy: CharacterSet.newlines).last ?? ""
        } catch {
            log("  ...file '\(filenames.lastGamePulse)' does not exist, falling back to '\(filenames.lastTime)'")
            do {
                text = try String(contentsOfFile: filenames.lastTime, encoding: .utf8).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).components(separatedBy: CharacterSet.newlines).last ?? ""
            } catch {
                let files: [String]
                do {
                    files = try FileManager.default.contentsOfDirectory(atPath: filenames.livePrefix)
                } catch {
                    logError("'rmud-live' directory does not exist or is inaccessible")
                    throw error
                }
                logError("Unable to load last time. Files in 'rmud-live' directory: \(files)")
                throw error
            }
            usedLasttime = true
        }
        if let value = UInt64(text) {
            gamePulse = value
            if usedLasttime {
                gamePulse *= 10 // from sec to game pulses
                try saveToDisk()
            }
        } else {
            throw GameTimeError.invalidFileFormat
        }
    }
    
    func saveToDisk() throws {
        try ("Please do not modify this file.\n" +
            "\(gamePulse)\n").write(toFile: filenames.lastGamePulse, atomically: settings.saveFilesAtomically, encoding: .utf8)
    }
}

enum GameTimeError: Error, CustomStringConvertible {
    case invalidFileFormat
        
    var description: String {
        switch self {
        case .invalidFileFormat: return "Invalid file format"
        }
    }
}

extension GameTimeError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}
