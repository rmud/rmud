import Foundation

extension Creature {
    // Parg1 is unmodified argument here (see special directive in interpreter).
    // Do_look order: 1. Look direction 2. Look at character 3. Look at object
    // 4. Edesc in room 6. Edesc in eq 7. Edesc in inv 8. Edesc of obj in room
    //
    func doLook(context: CommandContext) {
        //act("&1Вы нарушили правила игры!&2", "!Мтт", self, bRed(), nNrm())
        
        // Sample
        //act("&11и нарушил1(,а,о,и) правила игры!&2", .toSleeping,
        //    .toCreature(self), .text(bRed()), .text(nNrm()))
        
        //        if context.line.isEmpty {
        //            lookAtRoom(ignoreBrief: true)
        //            return
        //        }
        
        guard context.hasArguments else {
            lookAtRoom(ignoreBrief: true)
            return
        }

        // First, test for full direction name match
        // Allow abbreviating directions only after handling creatures and items
        if !context.argument1.isEmpty, let direction = Direction(context.argument1, allowAbbreviating: false, caseInsensitive: true) {
            look(inDirection: direction)
            return
        }
        
        if let creature1 = context.creature1 {
            look(atCreature: creature1)
            if self != creature1 {
                act("1*и посмотрел1(,а,о,и) на Вас.", .excludingCreature(self), .toCreature(creature1))
                act("1*и посмотрел1(,а,о,и) на 2в.", .toRoom, .excludingCreature(self), .excludingCreature(creature1))
            } else {
                act("1*и посмотрел1(,а,о,и) на себя.", .toRoom, .excludingCreature(self))
            }
            return
        }
        
        // Lastly, test for abbreviated direction name
        if !context.argument1.isEmpty, let direction = Direction(context.argument1, allowAbbreviating: true, caseInsensitive: true) {
            look(inDirection: direction)
            return
        }
        
        send("Здесь нет ничего с таким названием или именем.")
    }
    
    func doScan(context: CommandContext) {
        guard !isAffected(by: .blindness) else {
            act(spells.message(.blindness, "СЛЕП"), .toCreature(self))
            return
        }
        
        guard let room = inRoom else {
            send(messages.noRoom)
            return
        }

        let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }

        var found = false
        for direction in Direction.orderedDirections {
            guard let exit = room.exits[direction] else { continue }
            
            let isHiddenExit = exit.flags.contains(.hidden) && !holylight()
            if (isHiddenExit || exit.toRoom() == nil) && exit.description.isEmpty {
                continue
            }
            
            found = true
            // FIXME: spins
            look(inDirection: direction)
        }
        if !found {
            send("Вы не обнаружили ничего особенного.")
        }
    }
    
    func lookAtRoom(ignoreBrief: Bool /* = false */) {
        guard isAwake else { return }
        
        guard !isAffected(by: .blindness) else {
            act(spells.message(.blindness, "СЛЕП"), .toCreature(self))
            return
        }

        guard let room = inRoom else {
            send(messages.noRoom)
            return
        }
        
        let autostat = preferenceFlags?.contains(.autostat) ?? false
        if autostat {
            act("&1[&2] &3 [&4]&5",
                .toCreature(self), .text(bCyn()), .text(String(room.vnum)), .text(room.name), .text(room.flags.description), .text(nNrm()))
        } else {
            act("&1&2&3",
                .toCreature(self), .text(bCyn()), .text(room.name), .text(nNrm()))
        }
        
        let mapWidth = Int(player?.mapWidth ?? defaultMapWidth)
        let mapHeight = Int(player?.mapHeight ?? defaultMapHeight)
        
        let map: [[ColoredCharacter]]
        if preferenceFlags?.contains(.map) ?? false {
            map = player?.renderMap()?.fragment(near: room, playerRoom: room, horizontalRooms: mapWidth, verticalRooms: mapHeight) ?? []
        } else {
            map = []
        }
        let indent = "     "
        let description = indent + room.description.joined()
        let wrapped = description.wrapping(withIndent: indent, aroundTextColumn: map, totalWidth: Int(pageWidth), rightMargin: 1, bottomMargin: 0)
        
        send(wrapped.renderedAsString(withColor: true))
        
        send(bYel(), terminator: "")
        sendDescriptions(of: room.items, withGroundDescriptionsOnly: true, bigOnly: false)
        send(bRed(), terminator: "")
        sendDescriptions(of: room.creatures)
        send(nNrm(), terminator: "")
    }
    
    // argument - направление, куда игрок пытается смотреть
    // actual - куда реально смотрит
    func look(inDirection direction: Direction) {
        guard let inRoom = inRoom else {
            send(messages.noRoom)
            return
        }
        
        guard let exit = inRoom.exits[direction] else {
            send("\(direction.whereAtCapitalizedAndRightAligned): \(bGra())ничего особенного\(nNrm())")
            return
        }

        let toRoom = exit.toRoom()
        
        let autostat = preferenceFlags?.contains(.autostat) ?? false

        var roomVnumString = ""
        if autostat, let room = toRoom {
            roomVnumString = "[\(String(room.vnum).leftExpandingTo(minimumLength: 6))] "
        }
        
        let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }
        
        let isMisty = toRoom?.flags.contains(.mist) ?? false
        
        var exitDescription = exit.description
        if !exitDescription.isEmpty {
            if let lastScalar = exitDescription.unicodeScalars.last,
                    !CharacterSet.punctuationCharacters.contains(lastScalar) {
                exitDescription += "."
            }
        } else if let toRoom = toRoom,
            holylight() || !exit.flags.contains(anyOf: [.hidden, .closed]) {
            if canSee(toRoom) {
                exitDescription = toRoom.name
            } else if isMisty {
                exitDescription = "ничего невозможно разглядеть."
            } else {
                exitDescription = "слишком темно."
            }
        } else {
            exitDescription = "ничего особенного."
        }
        
        send("\(direction.whereAtCapitalizedAndRightAligned): \(roomVnumString)\(bGra())\(exitDescription)\(nNrm())")
        
        if exit.type != .none {
            if (exit.flags.contains(.hidden) && exit.flags != exit.prototype.flags) ||
                    !exit.flags.contains(anyOf: [.closed, .isDoor]) {
                return
            }
            let padding = autostat ? "         " : ""
            let openClosed = exit.flags.contains(.closed) ? "закрыт" : "открыт"
            send("\(padding)            \(nCyn())\(exit.type.nominative) \(openClosed)\(exit.type.adjunctiveEnd).\(nNrm())")
        }
        
        // arilou: для самозацикленных комнат не показывать, кто там, а то это легко опознаётся
        if let toRoom = toRoom, toRoom != inRoom &&
                !exit.flags.contains(.closed) {
            if canSee(toRoom) &&
                    (!exit.flags.contains(anyOf: [.hidden, .opaque]) || holylight()) {
                send(bYel(), terminator: "")
                sendDescriptions(of: toRoom.items, withGroundDescriptionsOnly: true, bigOnly: true)
                send(bRed(), terminator: "")
                sendDescriptions(of: toRoom.creatures)
                send(nNrm(), terminator: "")
            } else if isMisty {
                var size = 0
                for creature in toRoom.creatures {
                    size += Int(creature.size)
                    if size >= 100 {
                        send("\(bGra())...Смутные тени мелькают в тумане...\(nNrm())")
                        break
                    }
                }
            }
        }
    }
    
    func look(atCreature target: Creature) {
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
            
            let affectedAgeComponents = GameTimeComponents(gameSeconds: targetPlayer.affectedAgeSeconds())
            let affectedYears = affectedAgeComponents.years
            result +=
                affectedYears < 20 ? "юн1(ый,ая,ое,ые)" :
                affectedYears < 25 ? "молод1(ой,ая,ое,ые)" :
                affectedYears < 35 ? "взросл1(ый,ая,ое,ые)" :
                affectedYears < 60 ? "пожил1(ой,ая,ое,ые)" :
                affectedYears < 85 ? "стар1(ый,ая,ое,ые)" : "древн1(ий,яя,ее,ие)"
            
            result += " &."
            
            let raceName = target.race.info.namesByGender[target.gender] ?? "(раса неизвестна)"
            act(result, .excludingCreature(target), .toCreature(self), .text(raceName))
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
        
        act(result, .excludingCreature(target), .toCreature(self), .text(conditionString))
    }
}
