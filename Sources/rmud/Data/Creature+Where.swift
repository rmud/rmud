import Foundation

extension Creature {
    func isSameRoom(with creature: Creature) -> Bool {
        if let room = inRoom,
           let creatureRoom = creature.inRoom,
           room == creatureRoom {
            return true
        }
        return false
    }
    
    func isSameRoom(with item: Item) -> Bool {
        if let room = inRoom,
           let itemRoom = item.inRoom,
           room == itemRoom {
            return true
        }
        return false
    }

    func isSameArea(with creature: Creature) -> Bool {
        if let area = inRoom?.area,
           let creatureArea = creature.inRoom?.area,
           area.lowercasedName == creatureArea.lowercasedName {
            return true
        }
        return false
    }

    func isSameArea(with item: Item) -> Bool {
        if let area = inRoom?.area,
           let itemArea = item.inRoom?.area,
           area.lowercasedName == itemArea.lowercasedName {
            return true
        }
        return false
    }
}
