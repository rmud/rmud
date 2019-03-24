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
        for room in rooms {
            room.reset()
        }
    }

}
