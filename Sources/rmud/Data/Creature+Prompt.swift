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
            let experienceToLevel = classId.info.experienceForLevel(Int(level) + 1) - experience
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
            let path = movementPath.map { $0.direction.singleLetter }.joined()
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
        let isHolylight = self.preferenceFlags?.contains(.holylight) ?? false

        let targetName = nameNominativeVisible(of: target)
        let targetPercent = target.hitPointsPercentage()
        let statusColor = percentageColor(targetPercent)
        let targetCondition = CreatureCondition(hitPointsPercentage: targetPercent, position: target.position)
        var conditionString = targetCondition.shortDescription(gender: genderVisible(of: target))
        if isHolylight {
            conditionString += " \(target.hitPoints)ж"
        }
        let conditionStringColored = "\(statusColor)\(conditionString)\(nNrm())"
        
        return "[\(targetName):\(conditionStringColored)]"
    }
    
    private func statusAutoExits() -> String {
        guard let room = inRoom else { return "" }
                
        let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }
        var output = ""
        
        for direction in Direction.allDirectionsOrdered {
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
