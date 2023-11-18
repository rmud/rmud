import Foundation

class Players {
    static let sharedInstance = Players()
    
    var byLowercasedName: [String: Creature] = [:]
    var count: Int { return byLowercasedName.count }
    var scheduledForSaving = Set<Creature>()
    var quitting = Set<Creature>()

    // Generate index table for player files
    func load() {
        FileUtils.enumerateFiles(atPath: filenames.playersPrefix, withExtension: "plr", flags: .sortAlphabetically) { filename, stop in
            let playerName = getPlayerName(fromFilename: filename)
            let (isValid, _) = validateName(name: playerName, isNominative: true)
            guard isValid else {
                logFatal("Invalid playerfile name: \(filename)")
            }
            
            let creature = loadPlayer(name: playerName)
            byLowercasedName[creature.nameNominative.full.lowercased()] = creature
            creature.player!.account.creatures.insert(creature)
        }
        
        guard !byLowercasedName.isEmpty || settings.isPwipeMode else {
            logFatal("buildPlayerIndex: directory '\(filenames.playersPrefix)' doesn't contain any files with 'plr' extension. " +
                "If they were deleted intentionally, please rerun the game with parameter '--pwipe'.")
        }
        
        let playerCount = byLowercasedName.count
        log("  \(playerCount) player\(playerCount.ending("", "s", "s"))")
    }
    
    func save() {
        guard !scheduledForSaving.isEmpty else { return }
        
        FileUtils.createDirectoryIfNotExists(filenames.playersPrefix)
        
        let savedCount = scheduledForSaving.count
        for creature in scheduledForSaving {
            let playerDirectory = filenames.directoryName(forPlayerName: creature.nameNominative.full)
            let directory = URL(fileURLWithPath: filenames.playersPrefix, isDirectory: true)
                .appendingPathComponent(playerDirectory, isDirectory: true).relativePath
            do {
                let fileManager = FileManager.default
                var isDir: ObjCBool = false
                if !fileManager.fileExists(atPath: directory, isDirectory: &isDir) {
                    try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: false, attributes: nil)
                }
            } catch {
                logFatal("Unable to create directory '\(directory)' for '\(creature.nameNominative)': \(error.userFriendlyDescription)")
            }
            let filename = filenames.playerFileName(forPlayerName: creature.nameNominative.full)
            do {
                let configFile = ConfigFile()
                creature.save(to: configFile)
                try configFile.save(toFile: filename, atomically: settings.saveFilesAtomically)
            } catch {
                logFatal("Unable to save player '\(creature.nameNominative)': \(error.userFriendlyDescription)")
            }
        }
        scheduledForSaving.removeAll(keepingCapacity: true)
        log("Saved \(savedCount) player\(savedCount.ending("", "s", "s"))")
    }
    
    func delete(creature: Creature) {
        db.creaturesByUid.removeValue(forKey: creature.uid)
        byLowercasedName.removeValue(forKey: creature.nameNominative.full.lowercased())
        creature.player?.account.creatures.remove(creature)
        scheduledForSaving.remove(creature)

        let filename = filenames.playerFileName(forPlayerName: creature.nameNominative.full)
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: filename)
        } catch {
            logFatal("Unable to delete player '\(creature.nameNominative)': \(error.userFriendlyDescription)")
        }
    }
    
    func playerExists(name: String) -> Bool {
        return byLowercasedName[name.lowercased()] != nil
    }
    
    func getPlayer(name: String) -> Creature? {
        return byLowercasedName[name.lowercased()]
    }
    
    private func loadPlayer(name: String) -> Creature {
        let filename = filenames.playerFileName(forPlayerName: name)
        do {
            let configFile = try ConfigFile(fromFile: filename)
            return loadPlayer(name: name, from: configFile)
        } catch {
            logFatal("Unable to load player '\(name)' [\(filename)]: \(error.userFriendlyDescription)")
        }
    }
    
    private func loadPlayer(name: String, from playerFile: ConfigFile) -> Creature {
        guard !playerFile.isEmpty else {
            logFatal("Playerfile for player '\(name)' is empty")
        }

        let creature = Creature(from: playerFile, db: db)
        
        let nameNominativeLowercased = creature.nameNominative.full.lowercased()
        guard nameNominativeLowercased == name else {
            logFatal("Player name '\(nameNominativeLowercased)' does not match name obtained from filename: \(name)")
        }
        
        return creature
    }

    private func getPlayerName(fromFilename filename: String) -> String {
        let url = URL(fileURLWithPath: filename)
        let nameNFD = url.deletingPathExtension().lastPathComponent
        // Filenames on HFS (OS X) are in NFD (decomposed) form
        return nameNFD.precomposedStringWithCanonicalMapping
    }
}
