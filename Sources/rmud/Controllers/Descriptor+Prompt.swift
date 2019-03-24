import Foundation

extension Descriptor {
    func makePrompt() -> String {
        switch state {
        case .playing:
            return makeGamePrompt()
        default:
            break
        }
        return "> "
    }
    
    private func makeGamePrompt() -> String {
        guard let creature = creature else {
            return "> "
        }

        let nohpmvWhenMax = creature.preferenceFlags?.contains(.nohpmvWhenMax) ?? false

        var promptElements: [String] = []

        if let player = creature.player, player.adminInvisibilityLevel > 0 && creature.level >= Level.hero {
            promptElements.append("н\(player.adminInvisibilityLevel)")
        }

        if (creature.preferenceFlags?.contains(.displayHitPointsInPrompt) ?? false) && creature.berserkRounds == 0 {
            
            if creature.hitPoints != creature.affectedMaximumHitPoints() || !nohpmvWhenMax {
                promptElements.append("\(creature.statusHitPointsColor())\(creature.hitPoints)ж\(nNrm())")
            }
        }
        
        if creature.preferenceFlags?.contains(.displayMovementInPrompt) ?? false {
            if creature.movement != creature.affectedMaximumMovement() || !nohpmvWhenMax {
                promptElements.append("\(creature.statusMovementColor())\(creature.movement)б\(nNrm())")
            }
        }

        if let player = creature.player, player.preferenceFlags.contains(.displayXpInPrompt) &&
                creature.level < Level.hero {
            let experienceToLevel = creature.classId.info.experience(forLevel: creature.level + 1) - creature.experience
            promptElements.append("\(experienceToLevel)о")
        }
        
        if creature.preferenceFlags?.contains(.displayCoinsInPrompt) ?? false {
            promptElements.append("\(creature.gold)м")
        }
        
        let preferenceFlags = creature.preferenceFlags ?? []
        if preferenceFlags.contains(.autoexit) {
            let autoExits = statusAutoExits()
            if !autoExits.isEmpty {
                promptElements.append("Выходы:\(autoExits)")
            }
        }
        
        return promptElements.joined(separator: " ") + "> "
    }
    
    private func statusAutoExits() -> String {
        guard let room = creature?.inRoom else { return "" }
        
        guard let creature = creature else { return "" }
        
        let holylight = { creature.preferenceFlags?.contains(.holylight) ?? false }
        var output = ""
        
        for direction in Direction.orderedDirections {
            guard let exit = room.exits[direction] else { continue }
            
            let c = direction.singleLetter
            var exitDescription = ""
            
            if nil != exit.toRoom() {
                
                if exit.flags.contains(.locked) {
                    if holylight() {
                        exitDescription = "{\(c)}"
                    } else {
                        exitDescription = "(\(c))"
                    }
                } else if exit.flags.contains(.closed) {
                    exitDescription = "(\(c))"
                } else {
                    exitDescription = c
                }
                
                if exit.flags.contains(.hidden) {
                    if holylight() {
                        output += "[\(exitDescription)]"
                    }
                } else {
                    output += exitDescription
                }
            } else {
                // Highlight exits with vnums but without actual target room in red
                if exit.toVnum != nil && !exit.flags.contains(.imaginary) { // excluding automapper hints
                    output += "\(creature.bRed())\(c)\(creature.nNrm())"
                }
            }
        }
        return output
    }
}
