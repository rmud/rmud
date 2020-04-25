import Foundation

extension Creature {
    func makePrompt() -> String {
        let nohpmvWhenMax = preferenceFlags?.contains(.nohpmvWhenMax) ?? false

        var promptElements: [String] = []

        if let player = player, player.adminInvisibilityLevel > 0 && level >= Level.hero {
            promptElements.append("н\(player.adminInvisibilityLevel)")
        }

        if (preferenceFlags?.contains(.displayHitPointsInPrompt) ?? false) && berserkRounds == 0 {
            
            if hitPoints != affectedMaximumHitPoints() || !nohpmvWhenMax {
                promptElements.append("\(statusHitPointsColor())\(hitPoints)ж\(nNrm())")
            }
        }
        
        if preferenceFlags?.contains(.displayMovementInPrompt) ?? false {
            if movement != affectedMaximumMovement() || !nohpmvWhenMax {
                promptElements.append("\(statusMovementColor())\(movement)б\(nNrm())")
            }
        }

        if let player = player, player.preferenceFlags.contains(.displayXpInPrompt) &&
                level < Level.hero {
            let experienceToLevel = classId.info.experience(forLevel: level + 1) - experience
            promptElements.append("\(experienceToLevel)о")
        }
        
        if preferenceFlags?.contains(.displayCoinsInPrompt) ?? false {
            promptElements.append("\(gold)м")
        }
        
        if preferenceFlags?.contains(.autoexit) ?? false {
            let autoExits = statusAutoExits()
            if !autoExits.isEmpty {
                promptElements.append("Выходы:\(autoExits)")
            }
        }

        if preferenceFlags?.contains(.displayMovementInPrompt) ?? false, !movementPath.isEmpty {
            let path = movementPath.map { $0.singleLetter }.joined()
            promptElements.append("\(nCyn())\(path)\(nNrm())")
        }

        return promptElements.joined(separator: " ") + "> "
    }
    
    private func statusAutoExits() -> String {
        guard let room = inRoom else { return "" }
                
        let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }
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
                    output += "\(bRed())\(c)\(nNrm())"
                }
            }
        }
        return output
    }
}
