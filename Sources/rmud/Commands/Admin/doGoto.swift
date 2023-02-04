import Foundation

extension Creature {
    func doGoto(context: CommandContext) {
        guard let targetRoom = chooseTargetRoom(context: context) else {
            return
        }

        goto(room: targetRoom)
    }
    
    private func chooseTargetRoom(context: CommandContext) -> Room? {
        guard context.hasArguments else {
            send("Укажите номер комнаты, имя области, имя персонажа, название монстра или предмета.")
            return nil
        }
        
        if let creature = context.creature1 {
            return creature.inRoom
        } else if var item = context.item1 {
            while let container = item.inContainer {
                item = container
            }
            if let room = item.inRoom {
                return room
            } else if let wornBy = item.wornBy, canSee(wornBy), let inRoom = wornBy.inRoom {
                return inRoom
            } else if let carriedBy = item.carriedBy, canSee(carriedBy), let inRoom = carriedBy.inRoom {
                return inRoom
            }
        } else if let room = context.room1 {
            return room
        }
        return nil
    }
}
