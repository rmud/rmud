import Foundation

extension Area {
    func buildMap() {
        var originRoom: Room?
        
        if let originVnum = originVnum {
            if let room = db.roomsByVnum[originVnum] {
                originRoom = room
            } else {
                logWarning("Area \(lowercasedName): origin room \(originVnum) does not exist")
            }
        }
        
        if originRoom == nil {
            originRoom = rooms.first
        }
        
        if let originRoom = originRoom {
            let mapper = AreaMapper()
            map = mapper.buildAreaMap(startingRoom: originRoom)
            log("  \(lowercasedName): \(map.roomsCount) room\(map.roomsCount.ending("", "s", "s")), \(map.elementsCount) map element\(map.elementsCount.ending("", "s", "s")), origin: \(originRoom.vnum)")
            //print(map.debugPrint())
            
            if settings.debugSaveMaps {
                let filename = filenames.debugMapFilename(forAreaName: lowercasedName, startVnum: prototype.vnumRange.lowerBound, fileExtension: "dig")
                do {
                    log("  ...saving debug map to \(filename)")
                    try map.debugPrinted().write(toFile: filename, atomically: settings.saveFilesAtomically, encoding: .utf8)
                } catch {
                    fatalError()
                }
            }
        } else {
            map = AreaMap()
        }
    }
    
    func findUnlinkedRooms() -> [Room] {
        return rooms.filter { map.positionsByRoom[$0] == nil }
    }
}
