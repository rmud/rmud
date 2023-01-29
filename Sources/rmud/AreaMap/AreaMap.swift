import Foundation

public class AreaMap {
    public enum DigResult {
        case fromRoomDoesNotExist
        case toRoomAlreadyExists
        case toRoomExistsButNotOnSameLineWithFromRoom
        case longPassageAddedToExistingRoom
        case didAddRoomWithoutObstacles
        case didAddRoomShiftingObstacles
        case didNothing
        
        var debugDescription: String {
            switch self {
            case .fromRoomDoesNotExist: return "fromRoom does not exist"
            case .toRoomAlreadyExists: return "toRoom already exists"
            case .toRoomExistsButNotOnSameLineWithFromRoom: return "toRoom exists, but not on same line with fromRoom"
            case .longPassageAddedToExistingRoom: return "long passage added to existing room"
            case .didAddRoomWithoutObstacles: return "added room without obstacles"
            case .didAddRoomShiftingObstacles: return "added room shifting obstacles"
            case .didNothing: return "did nothing"
            }
        }
    }

    private(set) var mapElementsByPosition = [AreaMapPosition: AreaMapElement]()
    private(set) var positionsByRoom = [Room: AreaMapPosition]()

    var elementsCount: Int { return mapElementsByPosition.count }
    var roomsCount: Int { return positionsByRoom.count }
    private(set) var range = AreaMapRange(expandedWith: AreaMapPosition(0, 0, 0))
    private(set) var rangesByPlane = [Int: AreaMapRange]()

    init(startingRoom: Room? = nil) {
        if let startingRoom = startingRoom {
            let toPosition = AreaMapPosition(0, 0, 0)
            add(room: startingRoom, position: toPosition)
        }
    }

    func dig(toRoom: Room, fromRoom: Room, direction: Direction, distance: Int, drawPassage: Bool, onlyTest: Bool = false) -> (digResult: DigResult, isRerenderRequired: Bool) {
        var isRerenderRequired = false
        
        guard distance >= 1 else { return (.didNothing, isRerenderRequired) }
        
        if let toPosition = positionsByRoom[toRoom] {
            // redrawing still may be required (passage created)
            isRerenderRequired = true
            
            // if both rooms exist they are possibly at a distance and not linked yet, try to link them if they're on same row
            if drawPassage, let fromPosition = positionsByRoom[fromRoom] {
                let axis = AreaMapPosition.Axis(direction)
                if fromPosition.isOnSameLine(as: toPosition, axis: axis) {
                    var from = fromPosition.get(axis: axis)
                    var to = toPosition.get(axis: axis)
                    if from > to {
                        (to, from) = (from, to)
                    }
                    if to - from >= 2 {
                        if !onlyTest {
                            for at in from + 1...to - 1 {
                                var passagePosition = fromPosition
                                passagePosition.set(axis: axis, value: at)
                                mapElementsByPosition[passagePosition] = .passage(axis, toRoom: toRoom, fromRoom: fromRoom)
                            }
                        }
                        return (.longPassageAddedToExistingRoom, isRerenderRequired)
                    }
                } else {
                    return (.toRoomExistsButNotOnSameLineWithFromRoom, isRerenderRequired)
                }
            }
            return (.toRoomAlreadyExists, isRerenderRequired)
        }
        guard let fromPosition = positionsByRoom[fromRoom] else { return (.fromRoomDoesNotExist, isRerenderRequired) }

        var shiftDistance = 0
        for step in 1...distance {
            let intermediateOffset = AreaMapPosition(direction, step)
            let toPosition = fromPosition + intermediateOffset
            if mapElementsByPosition[toPosition] != nil {
                shiftDistance = distance - step + 1
                break
            }
        }
        
        var result: DigResult
        if shiftDistance > 0 {
            if !onlyTest {
                shift(from: fromPosition, direction: direction, distance: shiftDistance)
            }
            result = .didAddRoomShiftingObstacles
        } else {
            result = .didAddRoomWithoutObstacles
        }

        if !onlyTest {
            if drawPassage, distance >= 2 { // draw long passage
                let axis = AreaMapPosition.Axis(direction)
                for step in 1..<distance {
                    let intermediateOffset = AreaMapPosition(direction, step)
                    let passagePosition = fromPosition + intermediateOffset
                    mapElementsByPosition[passagePosition] = .passage(axis, toRoom: toRoom, fromRoom: fromRoom)
                }
            }
            // Draw room at the end of passage
            let toPosition = fromPosition + AreaMapPosition(direction, distance)
            add(room: toRoom, position: toPosition)

            isRerenderRequired = true
        }

        return (result, isRerenderRequired)
    }

    func add(room: Room, position: AreaMapPosition) {
        mapElementsByPosition[position] = .room(room)
        positionsByRoom[room] = position

        range.expand(with: position)

        if let planeRange = rangesByPlane[position.plane] {
            rangesByPlane[position.plane] = planeRange.expanded(with: position)
        } else {
            rangesByPlane[position.plane] = AreaMapRange(expandedWith: position)
        }
    }

    func shift(from: AreaMapPosition, direction: Direction, distance: Int) {
        let axis = AreaMapPosition.Axis(direction)
        let shift = AreaMapPosition(direction, distance)

        range.unite(with: range.shifted(by: shift))
        let oldRangesByPlane = rangesByPlane
        rangesByPlane.removeAll()
        
        for (plane, planeRange) in oldRangesByPlane {
            rangesByPlane[(AreaMapPosition(.plane, plane) + shift).plane] = planeRange.united(with: planeRange.shifted(by: shift))
        }
        
        let oldMapElementsByPosition = mapElementsByPosition
        mapElementsByPosition.removeAll()

        for (oldPosition, element) in oldMapElementsByPosition {
            guard (oldPosition - from).direction(axis: axis) == direction else {
                mapElementsByPosition[oldPosition] = element
                continue
            }

            let newPosition = oldPosition + shift
            mapElementsByPosition[newPosition] = element
            if case .room(let room) = element {
                positionsByRoom[room] = newPosition
            }
        }

        let fillFrom = (from + AreaMapPosition(direction, 1)).get(axis: axis)
        let fillTo = (from + AreaMapPosition(direction, distance)).get(axis: axis)
        let fillRange = min(fillFrom, fillTo)...max(fillFrom, fillTo)
        for (oldPosition, element) in oldMapElementsByPosition {
            guard oldPosition.get(axis: axis) == from.get(axis: axis) else {
                continue
            }

            switch element {
            case .room(let room) where room.hasValidExit(direction):
                if let neighborElement = oldMapElementsByPosition[oldPosition + AreaMapPosition(direction, 1)] {
                    
                    var shouldFillWithElement: AreaMapElement?
                    switch neighborElement {
                    case .room(let neighborRoom) where room.exits[direction]?.toRoom() == neighborRoom:
                        shouldFillWithElement = .passage(axis, toRoom: neighborRoom, fromRoom: room)
                    case .passage(let passageAxis, _, _) where passageAxis == axis:
                        shouldFillWithElement = neighborElement
                    default:
                        shouldFillWithElement = nil
                    }
                    if let fillElement = shouldFillWithElement {
                        for fillCoordinate in fillRange {
                            var position = oldPosition
                            position.set(axis: axis, value: fillCoordinate)
                            mapElementsByPosition[position] = fillElement
                        }
                    }
                }
            case .passage(let passageAxis, _, _) where passageAxis == axis:
                let fillElement = element
                for fillCoordinate in fillRange {
                    var position = oldPosition
                    position.set(axis: axis, value: fillCoordinate)
                    mapElementsByPosition[position] = fillElement
                }
            default:
                break
            }
        }
    }
    
    func debugPrint() {
        print(debugPrinted())
    }

    func debugPrinted() -> String {
        let elementWidth = 6 //14
        let columnCount = range.toInclusive.x - range.from.x + 1
        let lineCount = range.toInclusive.y - range.from.y + 1
        let separator = String(repeating: "=", count: columnCount * elementWidth) + "\n"
        
        var result = ""
        for plane in rangesByPlane.keys.sorted() {
            if !result.isEmpty {
                result += "\n"
            }
            result += "Plane \(plane):\n"

            for index in range.from.x ... range.toInclusive.x {
                result.append("\(index)".padding(toLength: elementWidth, withPad: " ", startingAt: 0))
            }
            result += "\n"
            result.append(separator)
            
            let fillLine = [String](repeating: " ".padding(toLength: elementWidth, withPad: " ", startingAt: 0), count: columnCount)
            var grid = [[String]](repeating: fillLine, count: lineCount)

            for (position, element) in mapElementsByPosition {
                if case let .passage(axis, toRoom, fromRoom) = element, (fromRoom.vnum == 1010 && toRoom.vnum == 1000) || (fromRoom.vnum == 1000 && toRoom.vnum == 1010) {
                    result += "_bp \(axis) to=\(toRoom) from=\(fromRoom) plane=\(position.plane) posX=\(position.x) posY=\(position.y)\n"
                }
                guard position.plane == plane else { continue }
                let atX = position.x - range.from.x
                let atY = position.y - range.from.y
                guard atX >= 0 && atY >= 0 else {
                    result += "ERROR: atX=\(atX) atY=\(atY) posX=\(position.x) posY=\(position.y) element=\(element)\n"
                    continue
                }
                switch element {
                case .room(let room):
                    grid[atY][atX] = String(room.vnum).padding(toLength: elementWidth, withPad: " ", startingAt: 0)
                case .passage(let axis, _, _):
                    switch axis {
                    case .y:
                        grid[atY][atX] = "|".padding(toLength: elementWidth, withPad: " ", startingAt: 0)
                    case .x:
                        grid[atY][atX] = "-".padding(toLength: elementWidth, withPad: " ", startingAt: 0)
                    case .plane:
                        grid[atY][atX] = "x".padding(toLength: elementWidth, withPad: " ", startingAt: 0)
                    }
                }
            }
            
            var first = true
            for (index, row) in grid.enumerated() {
                if !first {
                    result += "\n"
                } else {
                    first = false
                }
                for column in row {
                    result.append(column)
                }
                result.append(" || \(range.from.y + index)")
            }
        }

        return result
    }
}
