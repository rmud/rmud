extension Creature {
    func doMap(context: CommandContext) {
        enum ShowPlane {
            case current
            case specific(Int)
            case all
        }
        var showPlane: ShowPlane = .current

        var highlightRooms: Set<Int> = []
        var markRooms: Set<Int> = []

        let args = context.restOfString().components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        for arg in args {
            if arg.isEqualCI(toAny: ["все", "all"]) {
                showPlane = .all
            } else if let plane = Int(arg) {
                showPlane = .specific(plane)
            } else if isGodMode() {
                // Maybe it's a filter
                guard let (highlightRoomsNew, markRoomsNew) = processFilter(arg) else {
                    return
                }
                highlightRooms.formUnion(highlightRoomsNew)
                markRooms.formUnion(markRoomsNew)
            }
        }

        guard let renderedMap = player?.renderMap(highlightingRooms: highlightRooms, markingRooms: markRooms), let room = inRoom else {
            send("Карта этой области отсутствует.")
            return
        }
        
        let legendBlock = prepareLegendBlock(renderedMap.roomLegends)
        
        let outputBlock = ColoredCharacterBlock()
        var cursor = ColoredCharacterBlock.Cursor()
        
        switch showPlane {
        case .all:
            let planes = renderedMap.planes.sorted(by: >)
            for plane in planes {
                outputBlock.printLine(&cursor, text: "Уровень \(plane):", color: nNrm())
                let map = renderedMap.fragment(wholePlane: plane, playerRoom: room)
                let mapBlock = ColoredCharacterBlock(from: map)
                outputBlock.printLine(&cursor, block: mapBlock)
            }
            outputBlock.appendRight(block: legendBlock, spacing: 1)
            send(outputBlock.renderedAsString(withColor: true))
            return
        case .specific(let plane):
            outputBlock.printLine(&cursor, text: "Уровень \(plane):", color: nNrm())
            let map = renderedMap.fragment(wholePlane: plane, playerRoom: room)
            let mapBlock = ColoredCharacterBlock(from: map)
            outputBlock.printLine(&cursor, block: mapBlock)
            outputBlock.appendRight(block: legendBlock, spacing: 1)
            send(outputBlock.renderedAsString(withColor: true))
            return
        case .current:
            if let plane = renderedMap.plane(forRoom: room) {
                let map = renderedMap.fragment(wholePlane: plane, playerRoom: room)
                let mapBlock = ColoredCharacterBlock(from: map)
                outputBlock.printLine(&cursor, block: mapBlock)
                outputBlock.appendRight(block: legendBlock, spacing: 1)
                send(outputBlock.renderedAsString(withColor: true))
                return
            }
            // Unable to determine current plane
        }
        log("Room \(room.vnum) not found on map.")
        logToMud("Комната \(room.vnum) не найдена на карте.", verbosity: .brief)
    }

    private func prepareLegendBlock(
        _ roomLegends: [RenderedAreaMap.RoomLegendWithMetadata]
    ) -> ColoredCharacterBlock {
        let block = ColoredCharacterBlock()
        guard !roomLegends.isEmpty else { return block }

        var cursor = ColoredCharacterBlock.Cursor()
        block.printLine(&cursor, text: "Легенда", color: self.nNrm())
        block.newLine(&cursor)
        
        let isHolylight = self.preferenceFlags?.contains(.holylight) ?? false
        roomLegends.forEach { legendWithMetadata in
            let legend = legendWithMetadata.finalLegend
            block.print(&cursor, text: "\(legend.symbol)", color: self.nYel())
            block.print(&cursor, text: " \(legend.name)", color: self.nNrm())
            if isHolylight {
                let room = legendWithMetadata.room
                block.print(&cursor, text: " [\(room.vnum)]", color: self.cVnum())
            }
            block.newLine(&cursor)
        }
        return block
    }
    
    private func processFilter(_ arg: String) -> (highlightRooms: Set<Int>, markRooms: Set<Int>)? {
        let elements = arg.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard let fieldNameSubstring = elements[safe: 0] else {
            send("Некорректный фильтр: \(arg)")
            return nil
        }
        let valueSubstring = elements[safe: 1] ?? ""
        
        var highlightRooms: Set<Int> = []
        var markRooms: Set<Int> = []

        let fieldName = String(fieldNameSubstring)
        let value = String(valueSubstring)
        if fieldName.isAbbrevCI(of: "ксвойства") {
            guard let enumSpec = db.definitions.enumerations.enumSpecsByAlias["ксвойства"] else { fatalError("Enum spec not found") }
            let validValues = enumSpec.valuesByLowercasedName.keys.joined(separator: " ")
            guard !value.isEmpty else {
                send("Укажите свойство комнаты. Допустимые значения: \(validValues)")
                return nil
            }
            if let v64 = enumSpec.value(byAbbreviatedName: value),
                let bitIndex = UInt32(exactly: v64 - 1) {
                for room in inRoom?.area?.rooms ?? [] {
                    if room.flags.contains(RoomFlags(rawValue: 1 << bitIndex)) {
                        highlightRooms.insert(room.vnum)
                    }
                }
            } else {
                send("Неизвестное свойство комнаты: \(arg). Допустимые значения: \(validValues)")
                return nil
            }
        } else if fieldName.isAbbrevCI(of: "монстры") {
            let vnums = value.split(separator: ",", omittingEmptySubsequences: true).compactMap { Int($0) }
            for room in inRoom?.area?.rooms ?? [] {
                for creature in room.creatures {
                    guard let mobile = creature.mobile else { continue }
                    guard vnums.isEmpty || vnums.contains(mobile.vnum) else { continue }
                    guard let room = creature.inRoom else { continue }
                    markRooms.insert(room.vnum)
                }
            }
        } else if fieldName.isAbbrevCI(of: "путь") {
            guard !value.isEmpty else {
                send("Укажите название пути.")
                return nil
            }
            guard let path = inRoom?.area?.prototype.paths[value.lowercased()] else {
                send("Путь с таким названием не найден.")
                return nil
            }
            path.forEach { highlightRooms.insert($0) }
        } else {
            send("Неизвестное поле: \(fieldName)")
            return nil
        }
        return (highlightRooms, markRooms)
    }
}
