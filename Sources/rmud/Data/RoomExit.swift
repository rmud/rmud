class RoomExit {
    var prototype: RoomPrototype.ExitPrototype
    var toVnum: Int? // Where direction leads (vnum)

    var type: ExitType // Type of door
    var flags: ExitFlags // Exit info
    //var flagsOriginal: ExitFlags = [] // Assigned to exit_info on reboot
    var lock: LockInfo // Информация о замке
    var distance: UInt8 // Length of the passage on map

    var description: String // When look dir
    
    init(prototype: RoomPrototype.ExitPrototype) {
        self.prototype = prototype
        toVnum = prototype.toVnum
        type = prototype.type ?? .none
        flags = prototype.flags
        lock = LockInfo(prototype: prototype)
        distance = prototype.distance ?? 1
        description = prototype.description ?? ""
    }
    
    func toRoom(includingImaginaryExits: Bool = false) -> Room? { // Where direction leads
        guard let toVnum = toVnum else { return nil }
        guard includingImaginaryExits || !flags.contains(.imaginary) else { return nil }
        return db.roomsByVnum[toVnum]
    }
}
