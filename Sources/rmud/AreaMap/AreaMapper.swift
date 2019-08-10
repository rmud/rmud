import Foundation

class AreaMapper {
    struct RoomAndDirection: Hashable {
        let room: Room
        let direction: Direction
        
        static func ==(lhs: RoomAndDirection, rhs: RoomAndDirection) -> Bool {
            return lhs.room == rhs.room &&
                lhs.direction == rhs.direction
        }
        
        public func hash(into hasher: inout Hasher) {
            room.hash(into: &hasher)
            direction.hash(into: &hasher)
        }
    }
    
    // Prioritizes normal directions over interplane directions
    struct DirectionsQueue {
        private var queue: [RoomAndDirection] = []
        
        var isEmpty: Bool { return queue.isEmpty }
        var count: Int { return queue.count }
        
        mutating func removeAll(keepingCapacity: Bool) {
            queue.removeAll(keepingCapacity: keepingCapacity)
        }
        
        mutating func append(directionsOf room: Room) {
            for direction in Direction.orderedByMappingPriorityDirections {
                if room.hasValidExit(direction, includingImaginaryRooms: true) {
                    let roomAndDirection = RoomAndDirection(room: room, direction: direction)
                    append(roomAndDirection: roomAndDirection)
                }
            }
        }
        
        mutating func append(roomAndDirection: RoomAndDirection) {
            queue.append(roomAndDirection)
        }

        mutating func popFirst() -> RoomAndDirection? {
            if !queue.isEmpty {
                return queue.removeFirst()
            }
            return nil
        }
    }
    
    private enum Stage: CustomDebugStringConvertible {
        case addRoomsWithoutShiftingWithoutPlaneChanges
        case addRoomsWithShiftingWithoutPlaneChanges
        case addPlaneChanges
        
        var withoutShifting: Bool {
            return self == .addRoomsWithoutShiftingWithoutPlaneChanges
        }
        
        var withoutPlaneChanges: Bool {
            return self == .addRoomsWithoutShiftingWithoutPlaneChanges ||
                self == .addRoomsWithShiftingWithoutPlaneChanges
        }
            
        var next: Stage {
            switch self {
            case .addRoomsWithoutShiftingWithoutPlaneChanges:
                return .addRoomsWithShiftingWithoutPlaneChanges
            case .addRoomsWithShiftingWithoutPlaneChanges:
                return .addPlaneChanges
            case .addPlaneChanges:
                return .addRoomsWithoutShiftingWithoutPlaneChanges
            }
        }
        
        var debugDescription: String {
            switch self {
            case .addRoomsWithoutShiftingWithoutPlaneChanges:
                return "no shift / no plane changes"
            case .addRoomsWithShiftingWithoutPlaneChanges:
                return "shift / no plane changes"
            case .addPlaneChanges:
                return "shift / plane changes"
            }
        }
    }
    
    func buildAreaMap(startingRoom: Room) -> AreaMap {
        let areaMap = AreaMap(startingRoom: startingRoom)
        
        var queue = DirectionsQueue()
        var postponedShiftQueue = DirectionsQueue()
        var postponedCrossPlaneQueue = DirectionsQueue()
        var postponedLongPassagesQueue = DirectionsQueue()
        queue.append(directionsOf: startingRoom)
        
        var visited = Set<RoomAndDirection>()

        var dumpToFile = settings.debugSaveMapDiggingSteps
        var dump: String? = dumpToFile ? "" : nil
        var dumpRendered: String? = dumpToFile ? "" : nil
        var dumpStep = 0
        
        let renderMap: (_ currentRoom: Room?)->String = { currentRoom in
            var fragments: [[ColoredCharacter]] = []
            let configuration = RenderedAreaMap.RenderConfiguration(exploredRooms: .all, showUnexploredRooms: true)
            let renderedMap = RenderedAreaMap(areaMap: areaMap, renderConfiguration: configuration)
            let planes = renderedMap.planes.sorted(by: <)
            for plane in planes {
                let map = renderedMap.fragment(wholePlane: plane, playerRoom: currentRoom)
                let title = [ColoredCharacter]("<\(plane)>").padding(toLength: map.first?.count ?? 0, withPad: " ")
                var mapWithTitle = [title]
                mapWithTitle += map
                if fragments.isEmpty {
                    fragments = mapWithTitle
                } else {
                    fragments = self.mergeFragments(fragments, mapWithTitle)
                }
            }
            return fragments.renderedAsString(withColor: false)
        }
        
        var stage: Stage = .addRoomsWithoutShiftingWithoutPlaneChanges
        repeat {
            if dumpToFile {
                if !(dumpRendered?.isEmpty ?? false) {
                    dumpRendered? += "\n"
                }
                dumpRendered? += "Stage: \(stage.debugDescription): \(queue.count) room(s) in queue\n"
            }
            
            while let roomAndDirection = queue.popFirst() {
                
                guard !visited.contains(roomAndDirection) else { continue }

                let currentRoom = roomAndDirection.room
                let direction = roomAndDirection.direction

                guard let exit = currentRoom.exits[direction],
                        let nextRoom = exit.toRoom(includingImaginaryExits: true) else {
                    visited.insert(roomAndDirection)
                    continue
                }
                let distance = Int(exit.distance)
                let drawPassage = !exit.flags.contains(.imaginary)

                if stage.withoutPlaneChanges {
                    if direction == .up || direction == .down {
                        // Postpone vertical directions as much as possible
                        postponedCrossPlaneQueue.append(roomAndDirection: roomAndDirection)
                        continue
                    }
                }
                if stage.withoutShifting {
                    let (result, _) = areaMap.dig(toRoom: nextRoom, fromRoom: currentRoom, direction: direction, distance: distance, drawPassage: drawPassage, onlyTest: true)
                    if result != .didAddRoomWithoutObstacles && result != .longPassageAddedToExistingRoom {
                        // Can't add this room without obstacles, postpone.
                        // Do NOT add to visited yet!
                        postponedShiftQueue.append(roomAndDirection: roomAndDirection)
                        continue
                    }
                }
                if stage == .addPlaneChanges {
                    if direction != .up && direction != .down {
                        postponedShiftQueue.append(roomAndDirection: roomAndDirection)
                        continue
                    }
                }
                
                visited.insert(roomAndDirection)
                
                //print("--- dig \(roomAndDirection.direction.whereTo): from: \(currentRoom.vnum) to: \(nextRoom.vnum)")

                let dumpHeader: ()->() = {
                    dumpStep += 1
                    let header = "\n\(String(repeating: "-", count: 76))\n" +
                        "\(dumpStep): dig \(roomAndDirection.direction.whereToEng): from: \(currentRoom.vnum) '\(currentRoom.name)' to: \(nextRoom.vnum) '\(nextRoom.name)' \n" +
                    "\(String(repeating: "-", count: 76))\n"
                    dump? += header
                    dumpRendered? += header
                }
                
                if dumpToFile, dumpStep > settings.debugSaveMapDiggingStepsMaxSteps {
                    let text = "Dump file too big, aborting."
                    dump? += text
                    dumpRendered? += text
                    dumpToFile = false
                }

                // No cross area mapping
                guard nextRoom.area == startingRoom.area else {
                    if dumpToFile {
                        dumpHeader()
                        let text = "Skipping cross-area link\n"
                        dump? += text
                        dumpRendered? += text
                        dumpRendered? += renderMap(currentRoom)
                        dumpRendered? += "\n"
                    }
                    continue
                }
                
                let (result, _) = areaMap.dig(toRoom: nextRoom, fromRoom: currentRoom, direction: direction, distance: distance, drawPassage: drawPassage)
                //areaMap.debugPrint()
                if dumpToFile,
                        settings.debugSaveRoomAlreadyExistsSteps ||
                        result != .toRoomAlreadyExists {
                    dumpHeader()
                    let text = "Result: \(result.debugDescription)\n"
                    dump? += text
                    dump? += areaMap.debugPrinted()
                    dump? += "\n"

                    dumpRendered? += text
                    dumpRendered? += renderMap(currentRoom)
                    dumpRendered? += "\n"
                }
                switch result {
                case .didAddRoomWithoutObstacles,
                     .didAddRoomShiftingObstacles:
                    queue.append(directionsOf: nextRoom)
                case .toRoomExistsButNotOnSameLineWithFromRoom:
                    if drawPassage { // ignore imaginary passages
                        postponedLongPassagesQueue.append(roomAndDirection: roomAndDirection)
                    }
                default: break
                }
            }

            stage = stage.next
            switch stage {
            case .addRoomsWithoutShiftingWithoutPlaneChanges:
                queue = postponedShiftQueue
                postponedShiftQueue.removeAll(keepingCapacity: true)
            case .addRoomsWithShiftingWithoutPlaneChanges:
                queue = postponedShiftQueue
                postponedShiftQueue.removeAll(keepingCapacity: true)
            case .addPlaneChanges:
                queue = postponedCrossPlaneQueue
                postponedCrossPlaneQueue.removeAll(keepingCapacity: true)
            }
        } while !queue.isEmpty
        
        // Now all rooms are in their final places, one final try to draw missing passages:
        while let roomAndDirection = postponedLongPassagesQueue.popFirst() {
            let currentRoom = roomAndDirection.room
            let direction = roomAndDirection.direction
            guard let exit = currentRoom.exits[direction],
                    let nextRoom = exit.toRoom(includingImaginaryExits: true) else {
                continue
            }
            let distance = Int(exit.distance)
            let (result, _) = areaMap.dig(toRoom: nextRoom, fromRoom: currentRoom, direction: direction, distance: distance, drawPassage: true)
            if result == .toRoomExistsButNotOnSameLineWithFromRoom {
                if !exit.flags.contains(.torn) {
                    logWarning("Broken visual link between rooms \(currentRoom.vnum) and \(nextRoom.vnum): rooms are on different lines")
                }
            }
        }

        if settings.debugSaveRenderedMaps {
            let areaName = startingRoom.area?.lowercasedName ?? "noname"
            let startVnum = startingRoom.area?.vnumRange.lowerBound ?? 0
            let filename = filenames.debugMapFilename(forAreaName: areaName, startVnum: startVnum,  fileExtension: "ren")
            do {
                log("  ...saving debug rendered map to \(filename)")
                let map = renderMap(/* currentRoom: */ nil)
                try map.write(toFile: filename, atomically: settings.saveFilesAtomically, encoding: .utf8)
            } catch {
                fatalError()
            }
        }

        if settings.debugSaveMapDiggingSteps {
            let areaName = startingRoom.area?.lowercasedName ?? "noname"
            let startVnum = startingRoom.area?.vnumRange.lowerBound ?? 0
            let filename = filenames.debugMapDiggingStepsFilename(forAreaName: areaName, startVnum: startVnum, fileExtension: "dig-steps")
            do {
                log("  ...saving map digging steps to \(filename)")
                try dump?.write(toFile: filename, atomically: settings.saveFilesAtomically, encoding: .utf8)
            } catch {
                fatalError()
            }
            let filenameRendered = filenames.debugMapDiggingStepsFilename(forAreaName: areaName, startVnum: startVnum, fileExtension: "ren-steps")
            do {
                log("  ...saving rendered map digging steps to \(filenameRendered)")
                try dumpRendered?.write(toFile: filenameRendered, atomically: settings.saveFilesAtomically, encoding: .utf8)
            } catch {
                fatalError()
            }
        }
        
        return areaMap
    }
    
    private func mergeFragments(_ first: [[ColoredCharacter]], _ second: [[ColoredCharacter]]) -> [[ColoredCharacter]] {
        return zip(first, second).map { (left, right) -> [ColoredCharacter] in
            var result: [ColoredCharacter] = left
            result.append(" ")
            result += right
            return result
        }
    }
}
