import Foundation

extension Area {
    func createRooms() {
        for roomId in prototype.roomPrototypesByVnum.keys.sorted() {
            guard let roomPrototype = prototype.roomPrototypesByVnum[roomId] else { continue }
            guard let room = Room(prototype: roomPrototype, uid: db.createUid(), in: self) else {
                logFatal("Unable to instantiate room \(roomId)")
            }
            rooms.append(room)
            db.roomsByVnum[room.vnum] = room
        }
    }

    func reset() {
        log("Reset area \"\(lowercasedName)\")")
        defer { age = 0 }
    
        let message = "Сброс области \"\(lowercasedName)\" (\(description))."
        logToMud(message, verbosity: .complete)
        
        for room in rooms {
            room.reset()
        }
    }

    func hasPlayers() -> Bool {
        for room in rooms {
            for creature in room.creatures {
                if creature.isPlayer && !creature.isGodMode() {
                    return true
                }
            }
        }
        return false
    }
}
