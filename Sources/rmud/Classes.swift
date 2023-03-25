import Foundation

class Classes {
    static let sharedInstance = Classes()
    
    var classInfoById: [ClassInfo] =
        (0 ..< ClassId.count).map { _ in ClassInfo() }
    // FIXME: why races are configured in classes file?
    var raceInfoById: [RaceInfo] =
        (0 ..< Race.playerRacesCount).map { _ in RaceInfo() }
    
    init() {
    }
    
    // Classes information parsing
    func parseInfo() {
        let linesBySection: [(section: String, lines: [String])]
        do {
            let parser = MutliSectionInfoFileParser(filename: filenames.classes)
            linesBySection = try parser.parse()
        } catch {
            logFatal("Unable to load \(filenames.classes): \(error.userFriendlyDescription)")
        }
        
        for (section, lines) in linesBySection {
            processSection(section, lines: lines)
        }
    }

    private func processSection(_ section: String, lines: [String]) {
        // Section has optional parameters:
        // "EQUIPMENT 5" etc
        let parts = section.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let sectionName = parts.first else {
            logFatal("Invalid section name in \(filenames.classes)")
        }

        switch sectionName.lowercased() {
        case "профессии_аббревиатуры":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).abbreviation = line
            }
        case "профессии_муж":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).namesByGender[.masculine] = line
            }
        case "профессии_жен":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).namesByGender[.feminine] = line
            }
        case "расы_аббревиатуры":
            for (index, line) in lines.enumerated() {
                getRaceInfo(byId: index).abbreviation = line
            }
        case "расы_муж":
            for (index, line) in lines.enumerated() {
                getRaceInfo(byId: index).namesByGender[.masculine] = line
            }
        case "расы_жен":
            for (index, line) in lines.enumerated() {
                getRaceInfo(byId: index).namesByGender[.feminine] = line
            }
        case "расы_профессии":
            parseClassRaceAllowed(lines)
        case "профессии_наклонности":
            parseClassAlignment(lines)
        case "расы_характеристики":
            parseRaceInfo(lines)
        case "профессии_характеристики":
            parseClassInfo(lines)
        case "профессии_группы":
            for (index, line) in lines.enumerated() {
                guard let classGroupId = Int8(line), let classGroup = ClassGroup(rawValue: classGroupId) else {
                    logFatal("Invalid class group in \(filenames.classes): \(line)")
                }
                getClassInfo(byId: index).classGroup = classGroup
            }
        case "профессии_жизнь":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).startingHitPoints = Int(line) ?? 0
            }
        case "профессии_опыт":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).experienceMultiplier = Int(line) ?? 0
            }
        case "профессии_плюс_жизнь":
            parseClassHitGain(lines)
        case "профессии_отдых":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).movementUpdates = Int(line) ?? 0
            }
        case "умения":
            guard parts.count == 2, let classId = Int(parts[1]) else {
                logFatal("\(filenames.classes): умения: class id not specified or invalid")
            }
            parseSkills(classId: classId, lines)
        case "процент_умений":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).skillPercent = Int(line) ?? 0
            }
        case "названия_книг":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).spellbookType = line
            }
        case "местоимения_вин_книг":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).spellbookHimHerAccusative = line
            }
        case "запоминание":
            for (index, line) in lines.enumerated() {
                getClassInfo(byId: index).memorizationProcessName = line
            }
        case "позиции":
            guard parts.count == 2, let classId = Int(parts[1]) else {
                logFatal("\(filenames.classes): позиции: class id not specified or invalid")
            }
            return parseSlots(classId: classId, lines)
        case "экипировка":
            guard parts.count == 2, let classId = Int(parts[1]) else {
                logFatal("\(filenames.classes): экипировка: class id not specified or invalid")
            }
            parseEquipment(classId: classId, lines)
        default:
            logFatal("Unknown section name in \(filenames.classes): \(section)")
        }
    }
    
    private func getClassInfo(byId id: Int) -> ClassInfo {
        guard let classIdValue = UInt8(exactly: id),
            let classId = ClassId(rawValue: classIdValue) else {
                logFatal("When parsing \(filenames.classes): invalid class number \(id) encountered")
        }

        guard let classInfo = classInfoById[validating: Int(classId.rawValue)] else {
            logFatal("No classInfo for class \(classId.rawValue)")
        }
        return classInfo
    }
    
    private func getRace(fromInt id: Int) -> Race {
        guard let raceValue = UInt8(exactly: id),
                let race = Race(rawValue: raceValue) else {
            logFatal("When parsing \(filenames.classes): invalid race number \(id) encountered")
        }
        return race
    }
    
    private func getRaceInfo(byId id: Int) -> RaceInfo {
        let race = getRace(fromInt: id)
        if let raceInfo = raceInfoById[validating: Int(race.rawValue)] {
            return raceInfo
        }
        let raceInfo = RaceInfo()
        raceInfoById[Int(race.rawValue)] = raceInfo
        return raceInfo
    }
    
    private func parseClassRaceAllowed(_ lines: [String]) {
        guard lines.count == classInfoById.count else {
            logFatal("\(filenames.classes): расы_профессии: expected \(classInfoById.count) lines, got \(lines.count)")
        }
        for (index, line) in lines.enumerated() {
            let classInfo = getClassInfo(byId: index)
            
            let flags = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard flags.count == raceInfoById.count else {
                logFatal("\(filenames.classes): расы_профессии: expected \(raceInfoById.count) columns, got \(flags.count)")
            }
            var racesAllowed = Set<Race>()
            for (index, isRaceAllowed) in flags.enumerated() {
                let allowed = Int(isRaceAllowed) ?? 0
                guard allowed != 0 else { continue }
                let race = getRace(fromInt: index)
                racesAllowed.insert(race)
            }
            classInfo.racesAllowed = racesAllowed
        }
    }
    
    private func parseClassAlignment(_ lines: [String]) {
        guard lines.count == classInfoById.count else {
            logFatal("\(filenames.classes): профессии_наклонности: expected \(classInfoById.count) lines, got \(lines.count)")
        }
        for (index, line) in lines.enumerated() {
            let classInfo = getClassInfo(byId: index)
            let elements = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard elements.count == 2 else {
                logFatal("\(filenames.classes): профессии_наклонности: expected 2 values in range, got \(elements.count)")
            }
            let from = Int(elements[0]) ?? 0
            let to = Int(elements[1]) ?? 0
            classInfo.alignment = from...to
        }
    }
    
    private func parseRaceInfo(_ lines: [String]) {
        guard lines.count == raceInfoById.count else {
            logFatal("\(filenames.classes): расы_характеристики: expected \(raceInfoById.count) lines, got \(lines.count)")
        }
        for (index, line) in lines.enumerated() {
            let raceInfo = getRaceInfo(byId: index)
            let elements = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard elements.count == 16 else {
                logFatal("\(filenames.classes): расы_характеристики: expected 16 values, got \(elements.count)")
            }
            raceInfo.heightMale     = UInt(elements[0]) ?? 0
            raceInfo.heightFemale   = UInt(elements[1]) ?? 0
            raceInfo.heightDiceNum  = Int(elements[2]) ?? 0
            raceInfo.heightDiceSize = Int(elements[3]) ?? 0
            raceInfo.weightMale     = UInt(elements[4]) ?? 0
            raceInfo.weightFemale   = UInt(elements[5]) ?? 0
            raceInfo.weightDiceNum  = Int(elements[6]) ?? 0
            raceInfo.weightDiceSize = Int(elements[7]) ?? 0
            raceInfo.strength       = Int(elements[8]) ?? 0
            raceInfo.dexterity      = Int(elements[9]) ?? 0
            raceInfo.constitution   = Int(elements[10]) ?? 0
            raceInfo.intelligence   = Int(elements[11]) ?? 0
            raceInfo.wisdom         = Int(elements[12]) ?? 0
            raceInfo.charisma       = Int(elements[13]) ?? 0
            raceInfo.size           = UInt8(elements[14]) ?? 0
            raceInfo.movement       = Int(elements[15]) ?? 0
        }
    }
    
    private func parseClassInfo(_ lines: [String]) {
        guard lines.count == classInfoById.count else {
            logFatal("\(filenames.classes): профессии_характеристики: expected \(classInfoById.count) lines, got \(lines.count)")
        }
        for (index, line) in lines.enumerated() {
            let classInfo = getClassInfo(byId: index)
            let elements = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard elements.count == 5 else {
                logFatal("\(filenames.classes): профессии_характеристики: expected 5 values, got \(elements.count)")
            }
            classInfo.strength     = Int(elements[0]) ?? 0
            classInfo.dexterity    = Int(elements[1]) ?? 0
            classInfo.constitution = Int(elements[2]) ?? 0
            classInfo.intelligence = Int(elements[3]) ?? 0
            classInfo.wisdom       = Int(elements[4]) ?? 0
        }
    }
    
    private func parseClassHitGain(_ lines: [String]) {
        for (index, line) in lines.enumerated() {
            let classInfo = getClassInfo(byId: index)
            classInfo.hitPointGain = Dice(line) ?? Dice()
            let maximumGain = classInfo.hitPointGain.maximum()
            classInfo.hitPointUpdates = maximumGain
            classInfo.maxHitPerLevel = maximumGain
        }
    }
    
    private func parseSkills(classId: Int, _ lines: [String]) {
        let classInfo = getClassInfo(byId: classId)
        
        for line in lines {
            let elements = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard elements.count == 2 else {
                logFatal("\(filenames.classes): умения \(classId): expected 2 values separated by ':'")
            }
            guard let skillId = UInt16(elements[0]),
                let skill = Skill(rawValue: skillId),
                let level = UInt8(elements[1]),
                1 ... maximumMortalLevel ~= level else {
                    logFatal("\(filenames.classes): умения \(classId): invalid format")
            }
            classInfo.minimumLevelForSkill[skill] = level
        }
    }
    
    private func parseSlots(classId: Int, _ lines: [String]) {
        let classInfo = getClassInfo(byId: classId)

        guard lines.count == maximumMortalLevel else {
            logFatal("\(filenames.classes): позиции: expected \(maximumMortalLevel) lines, got \(lines.count)")
        }
        
        for (index, line) in lines.enumerated() {
            let level = index + 1
            let slotCountByCircle = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard slotCountByCircle.count == 9 else {
                logFatal("\(filenames.classes): позиции: expected 9 spell circles, got \(slotCountByCircle.count)")
            }
            var slotsPerCircle = ClassInfo.SlotsPerCircle()
            for (index, slotCountString) in slotCountByCircle.enumerated() {
                guard let slotCount = Int(slotCountString) else {
                    logFatal("\(filenames.classes): позиции: invalid format")
                    
                }
                slotsPerCircle[index + 1] = slotCount
            }
            classInfo.slotsPerCirclePerLevel[level] = slotsPerCircle
        }
    }
    
    private func parseEquipment(classId: Int, _ lines: [String]) {
        let classInfo = getClassInfo(byId: classId)
        
        for line in lines {
            let elements = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard elements.count == 2 else {
                logFatal("\(filenames.classes): экипировка \(classId): expected 2 values separated by ':'")
            }
            guard let vn = Int(elements[0]),
                  let posId = Int8(elements[1]) else {
                logFatal("\(filenames.classes): экипировка \(classId): invalid format")
            }
            var position: EquipmentPosition? = nil
            if posId != -1 {
                position = EquipmentPosition(rawValue: posId)
                if position == nil {
                    logFatal("\(filenames.classes): экипировка \(classId): invalid equipment slot")
                }
            }
            let eqSlot = ClassInfo.EquipmentSlot(vn: vn, pos: position)
            classInfo.newbieEquipment.append(eqSlot)
        }
    }
}
