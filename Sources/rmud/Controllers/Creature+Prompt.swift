import Foundation

extension Creature {
    func makePrompt() -> String {
        let nohpmvWhenMax = preferenceFlags?.contains(.nohpmvWhenMax) ?? false

        var promptElements: [String] = []

        if isGodMode() {
            promptElements.append("!")
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
                level <= maximumMortalLevel {
            let experienceToLevel = classId.info.experience(forLevel: level + 1) - experience
            promptElements.append("\(experienceToLevel)о")
        }
        
        if preferenceFlags?.contains(.displayCoinsInPrompt) ?? false {
            promptElements.append("\(gold)м")
        }
        
        if let fighting = fighting {
            if let tank = fighting.fighting {
                promptElements.append(statusHealth(target: tank))
            }
            promptElements.append(statusHealth(target: fighting))
        }

        if preferenceFlags?.contains(.displayMovementInPrompt) ?? false, !movementPath.isEmpty {
            let path = movementPath.map { $0.singleLetter }.joined()
            promptElements.append("Путь:\(nCyn())\(path)\(nNrm())")
        }
        
        if preferenceFlags?.contains(.autoexit) ?? false {
            let autoExits = statusAutoExits()
            if !autoExits.isEmpty {
                promptElements.append("Выходы:\(autoExits)")
            }
        }

        return promptElements.joined(separator: " ") + "> "
    }
                
    private func statusHealth(target: Creature) -> String {
        let name = nameNominativeVisible(of: target)
        let percent = target.hitPointsPercentage()
        let statusColor = percentageColor(percent)
        let condition = CreatureCondition(hitPointsPercentage: percent, position: position)
        let conditionString = condition.shortDescription(gender: genderVisible(of: target), color: statusColor, normalColor: nNrm())
        
        return "[\(name):\(conditionString)]"
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
