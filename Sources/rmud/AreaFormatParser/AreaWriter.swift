import Foundation

class AreaWriter {
    typealias EntityDumpFunction = ([Entity], FieldDefinitions) -> String
    
    let areaName: String
    let prototype: AreaPrototype
    let definitions: Definitions
    
    init(forAreaNamed areaName: String, prototype: AreaPrototype, definitions: Definitions) {
        self.areaName = areaName
        self.prototype = prototype
        self.definitions = definitions
    }
    
    func saveAreaPrototypes() {
        let areaDirectory = filenames.directoryName(forAreaName: areaName, startVnum: prototype.vnumRange.lowerBound)

        FileUtils.createDirectoryIfNotExists(areaDirectory)

        do {
            let output = prototype.save(for: .areaFile, with: definitions)
            let filename = filenames.areaFilename(forAreaName: areaName, startVnum: prototype.vnumRange.lowerBound, fileExtension: "area_")
            do {
                try output.write(toFile: filename, atomically: settings.saveFilesAtomically, encoding: .utf8)
            } catch {
                logFatal(error: error)
            }
        }
        
        do {
            let roomPrototypes = prototype.roomPrototypesByVnum.sorted { $0.key < $1.key }.map { $0.value }
            let output = saveRoomPrototypes(roomPrototypes, fieldDefinitions: definitions.roomFields)
            let filename = filenames.areaFilename(forAreaName: areaName, startVnum: prototype.vnumRange.lowerBound, fileExtension: "rooms")
            do {
                try output.write(toFile: filename, atomically: settings.saveFilesAtomically, encoding: .utf8)
            } catch {
                logFatal(error: error)
            }
        }

        do {
            let mobilePrototypes = prototype.mobilePrototypesByVnum.sorted { $0.key < $1.key }.map { $0.value }
            let output = saveMobilePrototypes(mobilePrototypes, fieldDefinitions: definitions.mobileFields)
            let filename = filenames.areaFilename(forAreaName: areaName, startVnum: prototype.vnumRange.lowerBound, fileExtension: "mobiles")
            do {
                try output.write(toFile: filename, atomically: settings.saveFilesAtomically, encoding: .utf8)
            } catch {
                logFatal(error: error)
            }
        }

        do {
            let itemPrototypes = prototype.itemPrototypesByVnum.sorted { $0.key < $1.key }.map { $0.value }
            let output = saveItemPrototypes(itemPrototypes, fieldDefinitions: definitions.itemFields)
            let filename = filenames.areaFilename(forAreaName: areaName, startVnum: prototype.vnumRange.lowerBound, fileExtension: "items")
            do {
                try output.write(toFile: filename, atomically: settings.saveFilesAtomically, encoding: .utf8)
            } catch {
                logFatal(error: error)
            }
        }
    }

    private func saveRoomPrototypes(_ prototypes: [RoomPrototype], fieldDefinitions: FieldDefinitions) -> String {
        var result = ""
        for (index, prototype) in prototypes.enumerated() {
            if index != 0 {
                result += "\n"
            }
            result += prototype.save(for: .areaFile, with: definitions)
        }
        return result
    }

    private func saveMobilePrototypes(_ prototypes: [MobilePrototype], fieldDefinitions: FieldDefinitions) -> String {
        var result = ""
        for (index, prototype) in prototypes.enumerated() {
            if index != 0 {
                result += "\n"
            }
            result += prototype.save(for: .areaFile, with: definitions)
        }
        return result
    }

    private func saveItemPrototypes(_ prototypes: [ItemPrototype], fieldDefinitions: FieldDefinitions) -> String {
        var result = ""
        for (index, prototype) in prototypes.enumerated() {
            if index != 0 {
                result += "\n"
            }
            result += prototype.save(for: .areaFile, with: definitions)
        }
        return result
    }
}
