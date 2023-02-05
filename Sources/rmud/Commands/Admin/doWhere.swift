import Foundation

extension Creature {
    private enum ItemIndex {
        case none
        case number(Int)
    }
    
    func doWhere(context: CommandContext) {
        guard context.hasArguments else {
            showPlayers()
            return
        }
        
        var index = 0
        
        for creature in context.creatures1 {
            if canSee(creature) && creature.inRoom != nil {
                index += 1
                showCreatureLocation(creature, index: index)
            }
        }
        
        for item in context.items1 {
            if canSee(item) {
                index += 1
                showItemLocation(item, index: .number(index))
            }
        }

        if index == 0 {
          send("Здесь нет ничего с таким именем.")
        }
    }

    private func showPlayers() {
        for d in networking.descriptors {
            guard d.state == .playing else { continue }
            guard let creature = d.creature else { continue }
            guard let inRoom = creature.inRoom else { continue }
            guard canSee(creature) else { continue }
            
            let name = creature.nameNominative.full
            let namePadded = name.rightExpandingTo(30)
            let roomVnum = Format.leftPaddedVnum(inRoom.vnum)
            
            send("\(bRed())\(namePadded)\(nNrm()) \(cVnum())[\(roomVnum)]\(nNrm()) \(inRoom.name)")
        }
    }
    
    private func showCreatureLocation(_ creature: Creature, index: Int) {
        guard let inRoom = creature.inRoom else { return }
        
        let indexPadded = String(index).leftExpandingTo(3)
        let vnum = Format.leftPaddedVnum(creature.mobile?.vnum)
        let name = creature.nameNominative.full
        let namePadded = name.rightExpandingTo(30)
        let roomVnum = Format.leftPaddedVnum(inRoom.vnum)

        send("М\(indexPadded). \(bRed())[\(vnum)] \(namePadded)\(nNrm()) \(cVnum())[\(roomVnum)]\(nNrm()) \(inRoom.name)")
    }
    
    private func showItemLocation(_ item: Item, index: ItemIndex) {
        var output = ""
        
        if case .number(let index) = index {
            let indexPadded = String(index).rightExpandingTo(3)
            output += "П\(indexPadded). \(item.nameNominative.full) "
        } else {
            output += "".rightExpandingTo(37)
        }
        
        if let inRoom = item.inRoom {
            let roomVnum = Format.leftPaddedVnum(inRoom.vnum)
            send("\(cVnum())[\(roomVnum)]\(nNrm()) \(inRoom.name)")
        } else if let carriedBy = item.carriedBy {
            output += "в руках у \(carriedBy.nameGenitive)"
            send(output)
            
            output = "".rightExpandingTo(37)
            if let inRoom = carriedBy.inRoom {
                let roomVnum = Format.leftPaddedVnum(inRoom.vnum)
                output += "\(cVnum())[\(roomVnum)]\(nNrm()) \(inRoom.name)"
            } else {
                output += "НЕИЗВЕСТНО ГДЕ!"
            }
            send(output)
        } else if let wornBy = item.wornBy {
            output += "в экипировке \(wornBy.nameGenitive)"
            send(output)
            
            output = "".rightExpandingTo(37)
            if let inRoom = wornBy.inRoom {
                let roomVnum = Format.leftPaddedVnum(inRoom.vnum)
                output += "\(cVnum())[\(roomVnum)]\(nNrm()) \(inRoom.name)"
            } else {
                output += "НЕИЗВЕСТНО ГДЕ!"
                
            }
            send(output)
        } else if let container = item.inContainer {
            output += "внутри \(container.nameGenitive)"
            send(output)
            
            showItemLocation(container, index: .none)
        } else {
          send("НЕИЗВЕСТНО ГДЕ!")
        }
    }
}
