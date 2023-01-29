import Foundation

class Room {
    var prototype: RoomPrototype
    var uid: UInt64
    weak var area: Area?
    
    var vnum: Int
    var name = ""
    var terrain: Terrain
    var description: [String] = []
    var extraDescriptions: [ExtraDescription] = []

    var exits: [RoomExit?] = Array(repeating: nil, count: Direction.count)
    var flags: RoomFlags = []
    var legend: RoomLegend?
    var items: [Item] = []
    var creatures: [Creature] = []
    var eventOverrides: [Event<RoomEventId>] = []

    init?(prototype: RoomPrototype, uid: UInt64, in area: Area) {
        self.prototype = prototype
        self.uid = uid
        self.area = area
        
        vnum = prototype.vnum
        name = prototype.name
        terrain = prototype.terrain
        description = prototype.description
        
        extraDescriptions = prototype.extraDescriptions

        flags = prototype.flags
        legend = prototype.legend

        exits = prototype.exits.map { exitPrototype in
            guard let exitPrototype = exitPrototype else { return nil }
            return RoomExit(prototype: exitPrototype)
        }
    }
    
    func hasValidExit(_ direction: Direction, includingImaginaryRooms: Bool = false) -> Bool {
        if let exit = exits[direction] {
            return exit.toRoom(includingImaginaryExits: includingImaginaryRooms) != nil
        }
        return false
    }

    func exitDestination(_ direction: Direction) -> (ExitDestination, toRoom: Room?)? {
        guard let exit = exits[direction], let toVnum = exit.toVnum else {
            return nil
        }
        guard let toRoom = db.roomsByVnum[toVnum] else {
            return (.invalid, nil)
        }
        guard toRoom.area == area else {
            return (.toAnotherArea, toRoom)
        }
        return (.insideArea, toRoom)
    }
    
    // FIXME: overrides which cancel action should probably be prioritized
    func override(eventIds: RoomEventId...) -> Event<RoomEventId> {
        let chosenId: RoomEventId
        if eventIds.isEmpty {
            assertionFailure()
            chosenId = .invalid
        } else {
            chosenId = .invalid // FIXME
        }
        //        for override in actionOverrides {
        //            if override.action == action {
        //                return override
        //            }
        //        }
        return Event<RoomEventId>(eventId: chosenId)
    }
    
    func override(eventId: RoomEventId) -> Event<RoomEventId> {
        return override(eventIds: eventId)
    }
}

extension Room: Equatable {
    public static func ==(lhs: Room, rhs: Room) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension Room: Hashable {
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}

extension Room: CustomDebugStringConvertible {
    var debugDescription: String {
        return "#\(vnum)"
    }
}
