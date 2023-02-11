extension Creature {
    func doMap(context: CommandContext) {
        let sendMap: (_ mapString: String)->() = { mapString in
            guard !mapString.isEmpty else {
                self.send("На этом уровне карта отсутствует.")
                return
            }
            self.send(mapString)
        }
        
        let sendLegends: (_ roomLegends: [RenderedAreaMap.RoomLegendWithMetadata])->() = { legendsWithMetadata in
            if !legendsWithMetadata.isEmpty {
                self.send("Легенда:")
            }
            let isHolylight = self.preferenceFlags?.contains(.holylight) ?? false

            legendsWithMetadata.forEach { legendWithMetadata in
                let legend = legendWithMetadata.finalLegend
                var line = "\(self.nYel())\(legend.symbol)\(self.nNrm()) \(legend.name)"
                if isHolylight {
                    let room = legendWithMetadata.room
                    line += " \(self.cVnum())[\(room.vnum)]\(self.nNrm())"
                }
                self.send(line)
            }
        }
        
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
            if arg.isEqualCI(toAny: ["все", "всё", "all"]) {
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
        
        switch showPlane {
        case .all:
            sendLegends(renderedMap.roomLegends)
            let planes = renderedMap.planes.sorted(by: >)
            for plane in planes {
                send("Уровень \(plane):")
                let map = renderedMap.fragment(wholePlane: plane, playerRoom: room)
                sendMap(map.renderedAsString(withColor: true))
            }
            return
        case .specific(let plane):
            sendLegends(renderedMap.roomLegends)
            send("Уровень \(plane):")
            let map = renderedMap.fragment(wholePlane: plane, playerRoom: room)
            sendMap(map.renderedAsString(withColor: true))
            return
        case .current:
            if let plane = renderedMap.plane(forRoom: room) {
                sendLegends(renderedMap.roomLegends)
                let map = renderedMap.fragment(wholePlane: plane, playerRoom: room)
                sendMap(map.renderedAsString(withColor: true))
                return
            }
            // Unable to determine current plane
        }
        log("Room \(room.vnum) not found on map.")
        logToMud("Комната \(room.vnum) не найдена на карте.", verbosity: .brief)
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
