import Foundation

class Db {
    static let sharedInstance = Db()
    
    var pileOfCoinsPrototype: ItemPrototype? {
        return itemPrototypesByVnum[1]
    }
    
    var corpsePrototype: ItemPrototype? {
        return itemPrototypesByVnum[2]
    }
    
    var areaEntitiesByLowercasedName: [String: AreaEntities] = [:]
    var areaPrototypesByLowercasedName: [String: AreaPrototype] = [:]
    var itemPrototypesByVnum: [Int: ItemPrototype] = [:]
    var mobilePrototypesByVnum: [Int: MobilePrototype] = [:]
    var socialsEntitiesByLowercasedName = [String: Entity]()

    let definitions = Definitions()

    var roomsByVnum: [Int: Room] = [:]
    var creaturesInGame: [Creature] = []
    var creaturesInGameByUid: [UInt64: Creature] = [:]
    var creaturesByUid: [UInt64: Creature] = [:]
    var creaturesFighting: [Creature] = []
    var creaturesDying: [Creature] = []
    var itemsInGame: [Item] = [] // FIXME: too slow, try to remove it
    var itemsByUid: [UInt64: Item] = [:]
    var itemsCountByVnum: [Int: Int] = [:]
    var mobilesCountByVnum: [Int: Int] = [:]

    func boot() throws {
        log("Initializing morpher")
        BenchmarkTimer.measure {
            guard morpher.tryEnabling() else {
                fatalError("Unable to enable morpher: self-tests failed")
            }
        }
        
        log("Loading game time")
        try gameTime.loadFromDisk()

        log("Loading last UID - NOT IMPLEMENTED")

        log("Loading balance tables")
        balance.parseInfo()
        
        log("Loading classes information")
        classes.parseInfo()
        
        log("Loading text files")
        try textFiles.load()
        
        log("Loading battle messages - NOT IMPLEMENTED")
        
        log("Loading spell descriptions - NOT IMPLEMENTED")
        //spells.parseInfo()
        
        log("Loading endings")
        try BenchmarkTimer.measure {
            try endings.load()
        }

        log("Building player command index")
        BenchmarkTimer.measure {
            commandInterpreter.buildCommandIndex(roles: .admin)
        }

        log("Registering area format definitions")
        try registerDefinitions()

        //log("Loading area info (universe)")
        //try db.loadUniverse() // TODO: deprecate in favor of AREA entity type

        log("Loading area info")
        try BenchmarkTimer.measure {
            try db.loadAreaInfo()
        }

        log("Loading world")
        try BenchmarkTimer.measure {
            try db.loadWorldFiles()
        }

        log("Creating prototypes")
        try BenchmarkTimer.measure {
            try db.createPrototypes()
        }

        log("Loading help files - NOT IMPLEMENTED")
        
        log("Loading emails - NOT IMPLEMENTED")
        
        log("Loading accounts")
        BenchmarkTimer.measure {
            accounts.load()
        }
        
        log("Loading players")
        BenchmarkTimer.measure {
            players.load()
        }
        
        log("Loading socials")
        try BenchmarkTimer.measure {
            try socials.load()
        }
        
        db.logUnusedEntityFields()
        
        guard !settings.saveAreasAfterLoad else { return }

        
        log("Sorting commands and spells - NOT IMPLEMENTED")
        
        log("Loading ban lists and xnames - NOT IMPLEMENTED")
        
        log("Loading dns cache - NOT IMPLEMENTED")
        
        log("Loading old passwords - NOT IMPLEMENTED")
        
        log("Updating rent files - NOT IMPLEMENTED")
        
        log("Creating areas")
        areaManager.createAreas()
        
        log("Creating rooms")
        BenchmarkTimer.measure {
            areaManager.createRooms()
        }
        
        log("Building area maps")
        BenchmarkTimer.measure {
            areaManager.buildAreaMaps()
        }

        log("Initial areas reset")
        BenchmarkTimer.measure {
            areaManager.resetAreas()
        }
        
    }
    
    func registerDefinitions() throws {
        log("  enumerations")
        try db.definitions.registerEnumerations()
        log("  areas")
        try db.definitions.registerAreaFields()
        log("  items")
        try db.definitions.registerItemFields()
        log("  rooms")
        try db.definitions.registerRoomFields()
        log("  mobiles")
        try db.definitions.registerMobileFields()
        log("  socials")
        try db.definitions.registerSocialFields()
    }
    
    func logUnusedEntityFields() {
        guard settings.debugLogUnusedEntityFields else { return }
        for (lowercasedName, areaEntities) in areaEntitiesByLowercasedName {
            areaEntities.areaEntity.logUntouchedFields(comment: "unused field", what: "область \(lowercasedName)")
            areaEntities.areaEntity.untouchAllFields()
        }
    }
    
    func createCreatureUid() -> UInt64 {
        while true {
            let creatureUid = UInt64.random()
            guard creaturesByUid[creatureUid] == nil else { continue }
            return creatureUid
        }
    }

    func createItemUid() -> UInt64 {
        while true {
            let itemUid = UInt64.random()
            guard itemsByUid[itemUid] == nil else { continue }
            return itemUid
        }
    }
}
