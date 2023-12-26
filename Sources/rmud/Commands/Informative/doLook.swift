import Foundation

extension Creature {
    // context.argument1 is unmodified argument here
    // doLook order:
    // - Look direction (full match or single letter)
    // - Look at creature
    // - Look at/in item
    // - Edesc in room
    // - Edesc in equipment
    // - Edesc in inventory
    // - Edesc of object in room
    // - Look direction (abbreviated)
    func doLook(context: CommandContext) {
        guard context.hasArguments else {
            lookAtRoom(ignoreBrief: true)
            return
        }

        // First, test for full direction name match
        // Allow abbreviating directions only after handling creatures and items
        if !context.argument1.isEmpty {
            if let direction = Direction(fullName: context.argument1) {
                look(inDirection: direction)
                return
            }
            if let direction = Direction(singleLetterName: context.argument1) {
                look(inDirection: direction)
                return
            }
        }
        
        if let creature = context.creature1 {
            look(atCreature: creature)
            if self != creature {
                act("1*и посмотрел1(,а,о,и) на Вас.", .excluding(self), .to(creature))
                act("1*и посмотрел1(,а,о,и) на 2в.", .toRoom, .excluding(self), .excluding(creature))
            } else {
                act("1*и посмотрел1(,а,о,и) на себя.", .toRoom, .excluding(self))
            }
            return
        }
        
        if let item = context.item1 {
            look(atItem: item)
            return
        }
        
        // Lastly, test for abbreviated direction name
        if !context.argument1.isEmpty,
           let direction = Direction(abbreviatedName: context.argument1) {
            look(inDirection: direction)
            return
        }
        
        send("Здесь нет ничего с таким названием или именем.")
    }
    
    private func look(atCreature target: Creature) {
        guard !descriptors.isEmpty else { return }
        
        let description = target.description.joined()
        if !description.isEmpty {
            let wrapped = description.wrapping(totalWidth: Int(pageWidth))
            if target.isPlayer {
                // FIXME: why cut it here and not in description editor?
                let trimmedAndEscaped = wrapped.components(separatedBy: .newlines).prefix(10).map { "* " + $0 }.joined(separator: "\n")
                send(trimmedAndEscaped)
            } else {
                send(wrapped)
            }
        }
        
        diagnose(target: target, showAppearance: true)
    }
    
    private func look(atItem item: Item) {
        let description = item.description.joined()
        if !description.isEmpty {
            let wrapped = description.wrapping(totalWidth: Int(pageWidth))
            send(wrapped)
        }

        let isCorpse = item.asContainer()?.flags.contains(.corpse) ?? false
        if !isCorpse {
            showItemConditionAndQuality(item)
            showItemRequiredSkill(item)
            showItemWear(item)
        }
        
        if item.isContainer() || item.isFountain() || item.isVessel() {
            look(inContainer: item)
        }
        
        if let note = item.asNote() {
            act("1*и внимательно проч1(ел,ла,ло,ли) @1в.", .toRoom, .excluding(self), .item(item))
            act("В @1п написано следующее:", .to(self), .item(item))
            let text = note.text.joined()
            let wrapped = text.wrapping(totalWidth: Int(pageWidth))
            send(wrapped)
        }
        
        if item.isReceipt() {
            look(atReceipt: item)
        }
    }
    
    // FIXME: move to data/races
    private static let racialFatiness: [Race: [UInt8]] = {
        var result: [Race: [UInt8]] = [:]
        //         если <, то: тощий худой стройный полный >= толстый
        result[.human]     = [ 130,  140,  165,     175 ]
        result[.highElf]   = [  96,  101,  117,     119 ]
        result[.wildElf]   = [  96,  101,  117,     119 ]
        result[.halfElf]   = [  96,  101,  117,     119 ]
        result[.gnome]     = [  42,   50,   52,     54  ]
        result[.dwarf]     = [ 137,  157,  162,     168 ]
        result[.kender]    = [  88,  101,  105,     107 ]
        // FIXME: placeholders:
        result[.minotaur]  = [ 137,  157,  162,     168 ]
        result[.barbarian] = [ 130,  140,  165,     175 ]
        result[.goblin]    = [  88,  101,  105,     107 ]
        return result
    }()
    
    // FIXME: move to data/races
    private static let racialHighness: [Race: [UInt8]] = {
        var result: [Race: [UInt8]] = [:]
        //
        //         если <, то: крошечный низкий средний высокий >= огромный
        result[.human]     = [ 163,      166,   180,    190 ]
        result[.highElf]   = [ 141,      145,   155,    160 ]
        result[.wildElf]   = [ 141,      145,   155,    160 ]
        result[.halfElf]   = [ 141,      145,   155,    160 ]
        result[.gnome]     = [  99,      103,   114,    117 ]
        result[.dwarf]     = [ 112,      114,   125,    129 ]
        result[.kender]    = [  98,      104,   122,    126 ]
        // FIXME: placeholders:
        result[.minotaur]  = [ 163,      166,   180,    190 ]
        result[.barbarian] = [ 163,      166,   180,    190 ]
        result[.goblin]    = [  98,      104,   122,    126 ]
        return result
    }()
    
    func diagnose(target: Creature, showAppearance: Bool) {
        if showAppearance, let targetPlayer = target.player {
            var result = "1и - это "
            
            if let drunk = target.drunk {
                if drunk > 8 {
                    result += "пьян1(ый,ая,ое,ые) "
                } else if drunk > 0 {
                    result += "немного пьян1(ый,ая,ое,ые) "
                }
            }

            if let fatiness = Creature.racialFatiness[target.race] {
                result +=
                    target.weight < fatiness[0] ? "тощ1(ий,ая,ее,ие) " :
                    target.weight < fatiness[1] ? "худ1(ой,ая,ое,ые) " :
                    target.weight < fatiness[2] ? "стройн1(ый,ая,ое,ые) " :
                    target.weight < fatiness[3] ? "полн1(ый,ая,ое,ые) " :
                    "толст1(ый,ая,ое,ые) "
            }
            
            if let highness = Creature.racialHighness[target.race] {
                result +=
                    target.height < highness[0] ? "крошечн1(ый,ая,ое,ые) " :
                    target.height < highness[1] ? "низк1(ий,ая,ое,ие) " :
                    target.height < highness[2] ? "средн1(ий,яя,ое,ие) " :
                    target.height < highness[3] ? "высок1(ий,ая,ое,ие) " :
                    "огромн1(ый,ая,ое,ые) "
            }
            
            let attractiveness = target.affectedCharisma() + (race == target.race ? 2 : 0) + (gender == target.gender ? 0 : 2)
            result +=
                attractiveness <= 1 ? "омерзительн1(ый,ая,ое,ые) " :
                attractiveness <= 4 ? "уродлив1(ый,ая,ое,ые) " :
                attractiveness <= 7 ? "отталкивающ1(ий,ая,ее,ие) " :
                attractiveness <= 10 ? "некрасив1(ый,ая,ое,ые) " :
                attractiveness <= 13 ? "непримечательн1(ый,ая,ое,ые) " :
                attractiveness <= 16 ? "миловидн1(ый,ая,ое,ые) " :
                attractiveness <= 19 ? "привлекательн1(ый,ая,ое,ые) " :
                attractiveness <= 22 ? "очаровательн1(ый,ая,ое,ые) " :
                "соблазнительн1(ый,ая,ое,ые) "
            
            let affectedYears = targetPlayer.affectedAgeYears()
            result +=
                affectedYears < 20 ? "юн1(ый,ая,ое,ые)" :
                affectedYears < 25 ? "молод1(ой,ая,ое,ые)" :
                affectedYears < 35 ? "взросл1(ый,ая,ое,ые)" :
                affectedYears < 60 ? "пожил1(ой,ая,ое,ые)" :
                affectedYears < 85 ? "стар1(ый,ая,ое,ые)" : "древн1(ий,яя,ее,ие)"
            
            result += " &."
            
            let raceName = target.race.info.namesByGender[target.gender] ?? "(раса неизвестна)"
            act(result, .excluding(target), .to(self), .text(raceName))
        }
        
        let percent = target.hitPointsPercentage()
        let statusColor = percentageColor(percent)
        let condition = CreatureCondition(hitPointsPercentage: percent, position: target.position)
        let conditionString = condition.longDescriptionPrepositional(gender: genderVisible(of: target), color: statusColor, normalColor: nNrm())

        var result = "1и &1"
        if !target.position.isStunnedOrWorse && target.isPlayer {
            result += " и выгляд1(и,и,и,я)т "
            let movePercent = target.movement * 100 / target.affectedMaximumMovement()
            result +=
                movePercent >= 100 ? "отдохнувш1(им,ей,им,ими)" :
                movePercent >= 90  ? "бодр1(ым,ой,ым,ыми)" :
                movePercent >= 75  ? "немного уставш1(им,ей,им,ими)" :
                movePercent >= 50  ? "уставш1(им,ей,им,ими)" :
                movePercent >= 25  ? "сильно уставш1(им,ей,им,ими)" :
                movePercent >= 10  ? "утомленн1(ым,ой,ым,ыми)" :
                "истощенн1(ым,ой,ым,ыми)"
        }
        result += "."
        
        act(result, .excluding(target), .to(self), .text(conditionString))
    }
    
    private func showItemConditionAndQuality(_ item: Item) {
        let conditionPercentage = item.conditionPercentage()
        let conditionColor = percentageColor(conditionPercentage)
        let condition = ItemCondition(
            conditionPercentage: conditionPercentage
        ).longDescriptionPrepositional(color: conditionColor, normalColor: nNrm())
        
        let itemName = item.nameNominative.full.capitalizingFirstLetter()
        if let quality = qualityString(item) {
            send("\(itemName) \(condition) и \(quality).")
        } else {
            send("\(itemName) \(condition).")
        }
    }
    
    private func qualityString(_ item: Item) -> String? {
        let quality = item.qualityPercentage
        if quality >= 250 {
            return "великолепного качества"
        } else if quality >= 150 {
            return "очень хорошего качества"
        } else if (quality >= 110) {
            return "хорошего качества"
        } else if (quality <= 40) {
            return "удручающего качества"
        } else if (quality <= 80) {
            return "невысокого качества"
        }
        return nil
    }
    
    private func showItemRequiredSkill(_ item: Item) {
        if let weapon = item.asWeapon() {
            let skillName = weapon.weaponType.skill.name
            send("Для использования требуется обладать умением \"\(skillName)\".")
        }
    }
    
    private func showItemWear(_ item: Item) {
        if item.wearFlags.contains(.finger) {
            act("Надева@1(е,е,е,ю)тся на палец.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.neck) {
            act("Надева@1(е,е,е,ю)тся на шею.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.neckAbout) {
            act("Надева@1(е,е,е,ю)тся вокруг шеи.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.body) {
            act("Надева@1(е,е,е,ю)тся на тело.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.head) {
            act("Надева@1(е,е,е,ю)тся на голову.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.face) {
            act("Надева@1(е,е,е,ю)тся на лицо.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.legs) {
            act("Надева@1(е,е,е,ю)тся на ноги.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.feet) {
            act("Надева@1(е,е,е,ю)тся на ступни ног.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.arms) {
            act("Надева@1(е,е,е,ю)тся на руки.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.hands) {
            act("Надева@1(е,е,е,ю)тся на кисти рук.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.shield) {
            act("Надева@1(е,е,е,ю)тся в качестве щита.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.about) {
            act("Надева@1(е,е,е,ю)тся вокруг тела.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.back) {
            act("Надева@1(е,е,е,ю)тся за спину.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.waist) {
            act("Надева@1(е,е,е,ю)тся вокруг пояса.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.wrist) {
            act("Надева@1(е,е,е,ю)тся на запястье.", .toSleeping, .to(self), .item(item))
        }
        if item.wearFlags.contains(.ears) {
            act("Надева@1(е,е,е,ю)тся в уши.", .toSleeping, .to(self), .item(item))
        }
        
        if item.isWeapon() {
            let sendLackOfStrengthMessage = {
                self.send("   ...но у Вас недостаточно сил, чтобы делать это хорошо.")
            }
            
            if item.wearFlags.contains(.shield) {
                act("Мо@1(жет,жет,жет,гут) использоваться в качестве основного оружия.",
                    .toSleeping, .to(self), .item(item))
                if weaponEfficiencyPercent(for: item, position: .wield) < 100 {
                    sendLackOfStrengthMessage()
                }
            }
            if item.wearFlags.contains(.hold) {
                act("Мо@1(жет,жет,жет,гут) использоваться в качестве вспомогательного оружия.",
                    .toSleeping, .to(self), .item(item))
                if weaponEfficiencyPercent(for: item, position: .hold) < 100 {
                    sendLackOfStrengthMessage()
                }
            }
            if item.wearFlags.contains(.twoHand) {
                act("Мо@1(жет,жет,жет,гут) использоваться в качестве двуручного оружия.",
                    .toSleeping, .to(self), .item(item))
                if weaponEfficiencyPercent(for: item, position: .twoHand) < 100 {
                    sendLackOfStrengthMessage()
                }
            }
        }

        if item.wearFlags.contains(.hold) && item.isLight() {
            act("Использу@1(ется,ется,ется,ются) в качестве источника света.",
                .toSleeping, .to(self), .item(item))
        }
    }
}
