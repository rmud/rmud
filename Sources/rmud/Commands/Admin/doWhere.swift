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

        send("М\(indexPadded). \(cMobileVnum())[\(vnum)] \(bRed())\(namePadded)\(nNrm()) \(cRoomVnum())[\(roomVnum)]\(nNrm()) \(inRoom.name)")
    }
        
    private func showItemLocation(_ item: Item, index: ItemIndex) {
        var output = ""
        let offset = 46
    
        if case .number(let index) = index {
            let indexPadded = String(index).leftExpandingTo(3)
            let itemVnum = Format.leftPaddedVnum(item.vnum)
            let itemName = item.nameNominative.full.rightExpandingTo(30)
            output += "П\(indexPadded). \(cItemVnum())[\(itemVnum)] \(bYel())\(itemName)\(nNrm())"
        } else {
            output += "".rightExpandingTo(offset)
        }
        output += " "
        
        if let inRoom = item.inRoom {
            let roomVnum = Format.leftPaddedVnum(inRoom.vnum)
            output += "\(cRoomVnum())[\(roomVnum)] \(bCyn())\(inRoom.name)\(nNrm())"
            send(output)
        } else if let carriedBy = item.carriedBy {
            if let vnum = carriedBy.mobile?.vnum {
                output += "\(nGrn())в руках у \(cMobileVnum())[\(vnum)] \(bRed())\(carriedBy.nameGenitive)\(nNrm())"
            } else {
                output += "\(nGrn())в руках у \(bRed())\(carriedBy.nameGenitive)\(nNrm())"
            }
            send(output)
            
            output = "".rightExpandingTo(offset)
            if let inRoom = carriedBy.inRoom {
                let roomVnum = Format.leftPaddedVnum(inRoom.vnum)
                output += "\(cRoomVnum())[\(roomVnum)]\(bCyn()) \(inRoom.name)\(nNrm())"
            } else {
                output += "НЕИЗВЕСТНО ГДЕ!"
            }
            send(output)
        } else if let wornBy = item.wornBy {
            if let vnum = wornBy.mobile?.vnum {
                output += "\(nGrn())в экипировке \(cMobileVnum())[\(vnum)] \(bRed())\(wornBy.nameGenitive)\(nNrm())"
            } else {
                output += "\(nGrn())в экипировке \(bRed())\(wornBy.nameGenitive)\(nNrm())"
            }
            send(output)
            
            output = "".rightExpandingTo(offset)
            if let inRoom = wornBy.inRoom {
                let roomVnum = Format.leftPaddedVnum(inRoom.vnum)
                output += "\(cRoomVnum())[\(roomVnum)] \(bCyn())\(inRoom.name)\(nNrm())"
            } else {
                output += "НЕИЗВЕСТНО ГДЕ!"
                
            }
            send(output)
        } else if let container = item.inContainer {
            output += "внутри \(cItemVnum())[\(container.vnum)] \(bYel())\(container.nameGenitive)\(nNrm())"
            send(output)
            
            showItemLocation(container, index: .none)
        } else {
          send("НЕИЗВЕСТНО ГДЕ!")
        }
    }
}
