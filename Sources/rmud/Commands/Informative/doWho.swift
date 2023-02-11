extension Creature {
    func doWho(context: CommandContext) {
        var showTitledOnly = false
        var namesToSearchLowercased: [String] = []
        
        while let word = context.scanWord(ignoringFillWords: false) {
            switch word.lowercased() {
            case "титулованные": showTitledOnly = true
            default: namesToSearchLowercased.append(word)
            }
        }
        
        let holylight = preferenceFlags?.contains(.holylight) ?? false
                    
        let chosenDescriptors = networking.descriptors.filter { descriptor in
            guard descriptor.state == .playing else { return false }
            guard let target = descriptor.creature else { return false }
            guard let targetPlayer = target.player else { return false }
            guard !targetPlayer.isLinkDead || holylight else { return false }
            guard canSee(target) else { return false }
            
            return true
        }
        let chosenCreatures = Set<Creature>(
            chosenDescriptors.compactMap { descriptor in
                return descriptor.creature
            }
        )
        let chosenPlayers = chosenCreatures.sorted { lhs, rhs in
            return lhs.nameNominative.full < rhs.nameNominative.full
        }.compactMap { creature in
            return creature.player
        }
        
        var playersCount = 0
        var output = ""
        for targetPlayer in chosenPlayers {
            let targetCreature = targetPlayer.creature
            
            guard !showTitledOnly || !targetPlayer.customTitle.isEmpty else {
                continue
            }
            if !namesToSearchLowercased.isEmpty {
                let nameLowercased = targetCreature.nameNominative.full.lowercased()
                var matches = true
                for searchString in namesToSearchLowercased {
                    guard nameLowercased.contains(searchString) else {
                        matches = false
                        break
                    }
                }
                guard matches else { continue }
            }
            
            let prefix: String
            
            let autostatPrefix: ()->String = {
                let levelString = String(targetCreature.level).leftExpandingTo(2, with: "0")
                let classAbbreviation = targetCreature.classId.info.abbreviation.leftExpandingTo(3)
                return "[\(levelString) \(classAbbreviation)]"
            }
            
            if playersCount == 0 {
                output +=
                    "\(nCyn())Игроки\n" +
                             "------\(nNrm())\n"
            }
            playersCount += 1
            if targetPlayer.preferenceFlags.contains(.autostat) {
                prefix = autostatPrefix()
            } else {
                prefix = ""
            }
            
            var format = "&1&2&3" // color on, prefix, title

            if targetPlayer.preferenceFlags.contains(.deaf) {
                format.append(" (глух2(,а,о,и))")
            }
            
            if targetPlayer.preferenceFlags.contains(.busy) {
                format.append(" (занят2(,а,о,ы))")
            }
            format.append("&4") // color off

            let titleToShow = targetPlayer.titleWithFallbackToRace(order: .nameThenRace)
            let flags: ActFlags = .toSleeping
            let isImmortal = !(player?.roles ?? []).isEmpty
            let args: [ActArgument] = [
                .to(self),
                .excluding(targetCreature),
                .text(isImmortal ? bWht() : bCyn()), // &1
                .text(!prefix.isEmpty ? prefix.appending(" ") : ""), // &2
                .text(titleToShow), // &3
                .text(nNrm()) // &4
            ]
            act(format, flags, args) { target, actOutput in
                output.append(actOutput)
                output.append("\n")
            }
        }

        if playersCount == 0 {
            if !namesToSearchLowercased.isEmpty {
                send("Персонажей с такими именами в игре нет.")
            } else {
                send("Никого нет.")
            }
        } else {
            var format = "\n&1" // &1 for color on
            if playersCount > 0 {
                format.append("#1 игрок#1(,а,ов)")
            }
            format.append(".&2") // color off
            
            act(format,
                .toSleeping,
                .to(self),
                .number(playersCount), // #2
                .text(nCyn()), // &1
                .text(nNrm()) // &2
            ) { target, actOutput in
                output += actOutput
            }
            
            // FIXME
            //page_string(ch->desc, buf, true);
            send(output)
            
            // FIXME: why here?
            if playersCount > networking.topPlayersCountSinceBoot {
                networking.topPlayersCountSinceBoot = playersCount
                //log("Top players count since boot: \(playersCount)")
                logToMud("Игра достигла пиковой нагрузки: \(playersCount) персонаж\(playersCount.ending("", "а", "ей"))", verbosity: .normal)
            }
        }
    }
}
