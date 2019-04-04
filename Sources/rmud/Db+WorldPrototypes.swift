import Foundation

extension Db {
    func loadAreaInfo() throws {
        try load(what: "area", with: areaFileExtensions)
    }

    func loadWorldFiles() throws {
        try load(what: "world", with: worldFileExtensions)
    }

    func createPrototypes() throws {
        for (lowercasedAreaName, areaEntities) in db.areaEntitiesByLowercasedName {
            
            let areaPrototype: AreaPrototype
            do {
                let entity = areaEntities.areaEntity
                entity.untouchAllFields()
                defer { entity.untouchAllFields() }

                guard let prototype = AreaPrototype(entity: areaEntities.areaEntity) else {
                    logWarning("Unable to create prototype for area: \(lowercasedAreaName)")
                    continue
                }
                areaPrototype = prototype
                
                entity.logUntouchedFields(comment: "unused field", what: "area \(areaPrototype.lowercasedName)")
                
                db.areaPrototypesByLowercasedName[lowercasedAreaName] = prototype
            }
            
            areaPrototype.roomPrototypesByVnum = Dictionary(
                    uniqueKeysWithValues: areaEntities.roomEntitiesByVnum.compactMap { id, entity in
                // FIXME: make closure for logging unused fields, don't touch fields if they're accessed outside of closure
                entity.untouchAllFields()
                defer { entity.untouchAllFields() }
                guard let prototype = RoomPrototype(entity: entity) else {
                    logWarning("Unable to create prototype for room: \(id), area: \(lowercasedAreaName)")
                    return nil
                }
                entity.logUntouchedFields(comment: "unused field", what: "room \(prototype.vnum)")
                return (id, prototype)
            })

            areaPrototype.mobilePrototypesByVnum = Dictionary(
                uniqueKeysWithValues: areaEntities.mobileEntitiesByVnum.compactMap { id, entity in
                    entity.untouchAllFields()
                    defer { entity.untouchAllFields() }
                    guard let prototype = MobilePrototype(entity: entity) else {
                        logWarning("Unable to create prototype for mobile: \(id), area: \(lowercasedAreaName)")
                        return nil
                    }
                    entity.logUntouchedFields(comment: "unused field", what: "mobile \(prototype.vnum)")
                    db.mobilePrototypesByVnum[id] = prototype
                    return (id, prototype)
            })

            areaPrototype.itemPrototypesByVnum = Dictionary(
                uniqueKeysWithValues: areaEntities.itemEntitiesByVnum.compactMap { id, entity in
                    entity.untouchAllFields()
                    defer { entity.untouchAllFields() }
                    guard let prototype = ItemPrototype(entity: entity) else {
                        logWarning("Unable to create prototype for item: \(id), area: \(lowercasedAreaName)")
                        return nil
                    }
                    entity.logUntouchedFields(comment: "unused field", what: "item \(prototype.vnum)")
                    db.itemPrototypesByVnum[id] = prototype
                    return (id, prototype)
            })
        }
    }
    
    func save(areaNamed areaName: String, prototype: AreaPrototype) {
        let writer = AreaWriter(forAreaNamed: areaName,
                                prototype: prototype,
                                definitions: db.definitions)
        writer.saveAreaPrototypes()
    }
    
    private func load(what: String, with extensions: [String]) throws {
        let parser = AreaFormatParser(db: db,
                                      definitions: db.definitions)
        
        let fileManager = FileManager.default
        let dotExtensions = extensions.map { ".\($0)" }
        var areaFileCount = 0
        var counters = [Int](repeating: 0, count: extensions.count)
        enumerateFiles(atPath: filenames.worldPrefix, flags: .sortAlphabetically) { filename, stop in
            let directory = URL(fileURLWithPath: filenames.worldPrefix, isDirectory: true)
            let fullName = directory.appendingPathComponent(filename, isDirectory: false).relativePath

            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: fullName, isDirectory: &isDir) else {
                return
            }
            guard !isDir.boolValue else {
                return
            }
            
            guard let extensionIndex  = dotExtensions.firstIndex(where: { filename.hasSuffix($0) }) else {
                //log("  WARNING: skipping file: \(filename)")
                return
            }
            
            //log("  \(filename)")
            
            do {
                try parser.load(filename: fullName)
            } catch {
                log("\(filenames.worldPrefix)/\(filename): \(error.userFriendlyDescription)")
                exit(1)
            }
            
            counters[extensionIndex] += 1
            areaFileCount += 1
        }
        
        log("  \(areaFileCount) \(what) file\(areaFileCount.ending("", "s", "s")), in particular:")
        for (i, ext) in extensions.enumerated()
            where counters[i] > 0 {
                log("    \(counters[i]) \(ext) file\(counters[i].ending("", "s", "s"))")
        }
    }
}
