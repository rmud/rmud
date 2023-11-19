import Foundation

class RoomPrototype {
    class ExitPrototype {
        var toVnum: Int?
        
        var type: ExitType?
        var flags: ExitFlags = []
        var lockKeyVnum: Int?
        var lockLevel: UInt8?
        var lockCondition: LockCondition?
        var lockDamage: UInt8?
        var distance: UInt8?
        var description = ""
        
        var hasOnlyRoom: Bool {
            guard toVnum != nil else { return false }
            guard type == nil &&
                flags.isEmpty &&
                lockKeyVnum == nil &&
                lockLevel == nil &&
                lockCondition == nil &&
                lockDamage == nil &&
                distance == nil &&
                description.isEmpty
                else {
                    return false
            }
            return true
        }
    }

    var vnum: Int // Required
    var name: String // Required
    var comment: [String] // Optional
    var terrain: Terrain // Required
    var description: [String] = [] // Required
    var extraDescriptions: [ExtraDescription] = [] // Optional

    // The rest are optional
    var exits: [ExitPrototype?] = Array(repeating: nil, count: Direction.count)
    var flags: RoomFlags = []
    var legend: RoomLegend?
    var mobilesToLoadCountByVnum: [Int: Int] = [:]
    var itemsToLoadCountByVnum: [Int: Int] = [:]
    var coinsToLoad: Int = 0
    var eventOverrides: [Event<RoomEventId>] = []

    var procedures: Set<Int> = []
    
    init?(entity: Entity) {
        // Required:
        guard let vnum = entity["комната"]?.int else {
            assertionFailure()
            return nil
        }

        self.vnum = vnum
        name = entity["название"]?.string ?? "Без названия"
        comment = entity["комментарий"]?.stringArray ?? []
        terrain = entity["местность"]?.uint8.flatMap { Terrain(rawValue: $0) } ?? .inside
        description = entity["описание"]?.stringArray ?? ["Без описания"]
        for i in entity.structureIndexes("дополнительно") {
            // FIXME: think of more intuitive structure field lookup
            guard let key = entity["дополнительно.ключ", i]?.string else {
                assertionFailure()
                continue
            }
            let description = ExtraDescription()
            description.keyword = key
            description.description = entity["дополнительно.текст", i]?.stringArray ?? []
            extraDescriptions.append(description)
        }
        
        let readExitProperties: (_ roomExit: ()->ExitPrototype, _ name: String, _ i: Int)->() = { roomExit, name, i in
            if let room = entity["\(name).комната", i]?.int {
                roomExit().toVnum = room
            }
            if let type = entity["\(name).тип", i]?.uint8 {
                roomExit().type = ExitType(rawValue: type) ?? ExitType.none
            }
            if let flags = entity["\(name).признаки", i]?.uint32 {
                let roomExit = roomExit()
                roomExit.flags = ExitFlags(rawValue: flags)
            }
            if let key = entity["\(name).ключ", i]?.int {
                roomExit().lockKeyVnum = key
            }
            if let key = entity["\(name).замок_ключ", i]?.int {
                roomExit().lockKeyVnum = key
            }
            if let difficulty = entity["\(name).сложность", i]?.uint8 {
                roomExit().lockLevel = difficulty
            }
            if let difficulty = entity["\(name).замок_сложность", i]?.uint8 {
                roomExit().lockLevel = difficulty
            }
            if let condition = entity["\(name).замок_состояние", i]?.uint8 {
                roomExit().lockCondition = LockCondition(rawValue: condition)
            }
            if let damage = entity["\(name).замок_повреждение", i]?.uint8 {
                roomExit().lockDamage = damage
            }
            if let distance = entity["\(name).расстояние", i]?.uint8 {
                roomExit().distance = distance
            }
            if let description = entity["\(name).описание", i]?.string {
                roomExit().description = description
            }
        }
        for i in entity.structureIndexes("проход") {
            guard let direction = entity["проход.направление", i]?.direction else { continue }
            readExitProperties({ exits.findOrCreate(in: direction) }, "проход", i)
        }
        for direction in Direction.allDirectionsOrdered {
            if let toRoom = entity[direction.nameForAreaFile]?.int {
                exits.findOrCreate(in: direction).toVnum = toRoom
            }
            // Exit descriptions
            if let description = entity["о" + direction.nameForAreaFile]?.string {
                exits.findOrCreate(in: direction).description = description
            }
            for i in entity.structureIndexes(direction.nameForAreaFile) {
                readExitProperties({ exits.findOrCreate(in: direction) }, direction.nameForAreaFile, i)
            }
        }
        
        // {Proc, vtLONG, vaLIST, (void*)prs_w_trig, NO_SPEC},
        
        flags = RoomFlags(rawValue: entity["ксвойства"]?.uint32 ?? 0)
        
        for i in entity.structureIndexes("легенда") {
            var legend = self.legend ?? RoomLegend()
            if let name = entity["легенда.название", i]?.string {
                legend.name = name
            }
            if let symbolString = entity["легенда.символ", i]?.string, let symbol = symbolString.first {
                legend.symbol = symbol
            }
            self.legend = legend
        }

        if let mobiles = entity["монстры"]?.dictionary {
            for (vnumRaw, countRawOrNil) in mobiles {
                guard let mobileVnum = Int(exactly: vnumRaw) else {
                    logError("Room \(vnum): 'монстры': invalid mobile vnum \(vnumRaw)")
                    continue
                }
                let countRaw = countRawOrNil ?? 1
                guard let count = Int(exactly: countRaw),
                        count > 0 else {
                    logError("Room \(vnum): 'монстры': mobile \(mobileVnum): invalid count \(countRaw)")
                    continue
                }
                mobilesToLoadCountByVnum[mobileVnum] = count
            }
        }
        
        if let items = entity["предметы"]?.dictionary {
            for (vnumRaw, countRawOrNil) in items {
                guard let itemVnum = Int(exactly: vnumRaw) else {
                    logError("Room \(vnum): 'предметы': invalid item vnum \(vnumRaw)")
                    continue
                }
                let countRaw = countRawOrNil ?? 1
                guard let count = Int(exactly: countRaw),
                        count > 0 else {
                    logError("Room \(vnum): 'предметы': item vnum \(itemVnum): invalid count \(countRaw)")
                    continue
                }
                itemsToLoadCountByVnum[itemVnum] = count
            }
        }
        
        coinsToLoad = entity["деньги"]?.int ?? 0

        for i in entity.structureIndexes("кперехват") {
            guard let eventIdValue = entity["кперехват.событие", i]?.uint16,
                    let eventId = RoomEventId(rawValue: eventIdValue) else {
                assertionFailure()
                continue
            }
            var eventOverride = Event<RoomEventId>(eventId: eventId)
            
            if let actionFlagsValue = entity["кперехват.выполнение", i]?.uint8 {
                eventOverride.actionFlags = EventActionFlags(rawValue: actionFlagsValue)
            }
            // FIXME: rename to "персонажу"
            if let toPlayer = entity["кперехват.игроку", i]?.string {
                eventOverride.toActor = toPlayer
            }
            if let toVictim = entity["кперехват.жертве", i]?.string {
                eventOverride.toVictim = toVictim
            }
            if let toRoomExcludingActor = entity["кперехват.комнате", i]?.string {
                eventOverride.toRoomExcludingActor = toRoomExcludingActor
            }

            eventOverrides.append(eventOverride)
        }
        
        if let procedures = entity["процедура"]?.list {
            self.procedures = Set(procedures.compactMap {
                guard let procedure = Int(exactly: $0) else {
                    logError("Room \(vnum): 'процедура': \($0) is out of range")
                    return nil
                }
                return procedure
            })
        }
    }
    
    func save(for style: Value.FormattingStyle, with definitions: Definitions) -> String {
        var result = "КОМНАТА \(Value(number: vnum).formatted(for: style))\n"
        result += "  НАЗВАНИЕ \(Value(line: name).formatted(for: style))\n"
        if !comment.isEmpty {
            result += "  КОММЕНТАРИЙ \(Value(longText: comment).formatted(for: style, continuationIndent: 14))\n"
        }
        do {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["местность"]
            result += "  МЕСТНОСТЬ \(Value(enumeration: terrain).formatted(for: style, enumSpec: enumSpec))\n"
        }
        result += "  ОПИСАНИЕ \(Value(longText: description).formatted(for: style, continuationIndent: 11))\n"
        
        for extra in extraDescriptions {
            result += structureIfNotEmpty("ДОПОЛНИТЕЛЬНО") { content in
                if !extra.keyword.isEmpty {
                    content += "    КЛЮЧ \(Value(line: extra.keyword).formatted(for: style))\n"
                }
                if !extra.description.isEmpty {
                    content += "    ТЕКСТ \(Value(longText: extra.description).formatted(for: style, continuationIndent: 10))\n"
                }
            }
        }
        
        for direction in Direction.allDirectionsOrdered {
            let uppercasedDirection = direction.nameForAreaFile.uppercased()
            guard let exitPrototype = exits[direction] else { continue }
            if exitPrototype.hasOnlyRoom, let toVnum = exitPrototype.toVnum { // use short form
                result += "  \(uppercasedDirection) \(Value(number: toVnum).formatted(for: style))\n"
            } else {
                result += structureIfNotEmpty(uppercasedDirection) { content in
                    if let toVnum = exitPrototype.toVnum {
                        content += "    КОМНАТА \(Value(number: toVnum).formatted(for: style))\n"
                    }
                    if let type = exitPrototype.type {
                        let enumSpec = definitions.enumerations.enumSpecsByAlias["\(direction.nameForAreaFile).тип"]
                        content += "    ТИП \(Value(enumeration: type).formatted(for: style, enumSpec: enumSpec))\n"
                    }
                    if !exitPrototype.flags.isEmpty {
                        let enumSpec = definitions.enumerations.enumSpecsByAlias["\(direction.nameForAreaFile).признаки"]
                        content += "    ПРИЗНАКИ \(Value(flags: exitPrototype.flags).formatted(for: style, enumSpec: enumSpec))\n"
                    }
                    if let keyVnum = exitPrototype.lockKeyVnum {
                        content += "    ЗАМОК_КЛЮЧ \(Value(number: keyVnum).formatted(for: style))\n"
                    }
                    if let lockLevel = exitPrototype.lockLevel {
                        content += "    ЗАМОК_СЛОЖНОСТЬ \(Value(number: lockLevel).formatted(for: style))\n"
                    }
                    if let lockCondition = exitPrototype.lockCondition {
                        let enumSpec = definitions.enumerations.enumSpecsByAlias["\(direction.nameForAreaFile).замок_состояние"]
                        content += "    ЗАМОК_СОСТОЯНИЕ \(Value(enumeration: lockCondition).formatted(for: style, enumSpec: enumSpec))\n"
                    }
                    if let lockDamage = exitPrototype.lockDamage {
                        content += "    ЗАМОК_ПОВРЕЖДЕНИЕ \(Value(number: lockDamage).formatted(for: style))\n"
                    }
                    if let distance = exitPrototype.distance {
                        content += "    РАССТОЯНИЕ \(Value(number: distance).formatted(for: style))\n"
                    }
                    if !exitPrototype.description.isEmpty {
                        content += "    ОПИСАНИЕ \(Value(line: exitPrototype.description).formatted(for: style))\n"
                    }
                }
            }
        }
        
        if !flags.isEmpty {
            let enumSpec = definitions.enumerations.enumSpecsByAlias["ксвойства"]
            result += "  КСВОЙСТВА \(Value(flags: flags).formatted(for: style, enumSpec: enumSpec))\n"
        }
        
        if let legend = legend {
            result += structureIfNotEmpty("ЛЕГЕНДА") { content in
                if !legend.name.isEmpty {
                    content += "    НАЗВАНИЕ \(Value(line: legend.name).formatted(for: style))\n"
                }
                if legend.symbol != RoomLegend.defaultSymbol {
                    content += "    СИМВОЛ \(Value(line: "\(legend.symbol)").formatted(for: style))\n"
                }
            }
        }
        
        if !mobilesToLoadCountByVnum.isEmpty {
            let mobilesToLoad = mobilesToLoadCountByVnum.mapValues { $0 != 1 ? $0 : nil } // use short form
            result += "  МОНСТРЫ \(Value(dictionary: mobilesToLoad).formatted(for: style))\n"
        }
        
        if !itemsToLoadCountByVnum.isEmpty {
            let itemsToLoad = itemsToLoadCountByVnum.mapValues { $0 != 1 ? $0 : nil } // use short form
            result += "  ПРЕДМЕТЫ \(Value(dictionary: itemsToLoad).formatted(for: style))\n"
        }

        if coinsToLoad != 0 {
            result += "  ДЕНЬГИ \(Value(number: coinsToLoad).formatted(for: style))\n"
        }
        
        for eventOverride in eventOverrides {
            result += structureIfNotEmpty("КПЕРЕХВАТ") { content in
                do {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["кперехват.событие"]
                    content += "    СОБЫТИЕ \(Value(enumeration: eventOverride.eventId).formatted(for: style, enumSpec: enumSpec))\n"
                }
                do {
                    let enumSpec = definitions.enumerations.enumSpecsByAlias["кперехват.выполнение"]
                    content += "    ВЫПОЛНЕНИЕ \(Value(flags: eventOverride.actionFlags).formatted(for: style, enumSpec: enumSpec))\n"
                }
                if let toActor = eventOverride.toActor {
                    content += "    ИГРОКУ \(Value(line: toActor).formatted(for: style))\n"
                }
                if let toVictim = eventOverride.toVictim {
                    content += "    ЖЕРТВЕ \(Value(line: toVictim).formatted(for: style))\n"
                }
                if let toRoomExcludingActor = eventOverride.toRoomExcludingActor {
                    content += "    КОМНАТЕ \(Value(line: toRoomExcludingActor).formatted(for: style))\n"
                }
            }
        }
        
        if !procedures.isEmpty {
            result += "  ПРОЦЕДУРА \(Value(list: procedures).formatted(for: style))\n"
        }
        
        return result
    }
}

private extension Array where Element == RoomPrototype.ExitPrototype? {
    mutating func findOrCreate(in direction: Direction) -> RoomPrototype.ExitPrototype {
        if let exit = self[direction] {
            return exit
        }
        let exit = RoomPrototype.ExitPrototype()
        self[direction] = exit
        return exit
    }
}
