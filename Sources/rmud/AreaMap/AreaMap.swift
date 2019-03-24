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
    private(set) var range = AreaMapRange(AreaMapPosition(0, 0, 0))
    private(set) var rangesByPlane = [Int: AreaMapRange]()
    private(set) var version = 0

    init(startingRoom: Room? = nil) {
        if let startingRoom = startingRoom {
            let toPosition = AreaMapPosition(0, 0, 0)
            add(room: startingRoom, position: toPosition)
        }
    }

    func dig(toRoom: Room, fromRoom: Room, direction: Direction, distance: Int, drawPassage: Bool, onlyTest: Bool = false) -> DigResult {
        
        guard distance >= 1 else { return .didNothing }
        
        if let toPosition = positionsByRoom[toRoom] {
            // redrawing still may be required (passage created)
            defer { version = version &+ 1 }
            
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
                                mapElementsByPosition[passagePosition] = .passage(axis)
                            }
                        }
                        return .longPassageAddedToExistingRoom
                    }
                } else {
                    return .toRoomExistsButNotOnSameLineWithFromRoom
                }
            }
            return .toRoomAlreadyExists
        }
        guard let fromPosition = positionsByRoom[fromRoom] else { return .fromRoomDoesNotExist }

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
                    mapElementsByPosition[passagePosition] = .passage(axis)
                }
            }
            // Draw room at the end of passage
            let toPosition = fromPosition + AreaMapPosition(direction, distance)
            add(room: toRoom, position: toPosition)

            version = version &+ 1
        }

        return result
    }

    func add(room: Room, position: AreaMapPosition) {
        mapElementsByPosition[position] = .room(room)
        positionsByRoom[room] = position

        range.expand(with: position)

        if let planeRange = rangesByPlane[position.plane] {
            rangesByPlane[position.plane] = planeRange.expanded(with: position)
        } else {
            rangesByPlane[position.plane] = AreaMapRange(position)
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

        let fillElement = AreaMapElement.passage(axis)
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
                    
                    var shouldFill: Bool
                    switch neighborElement {
                    case let .room(neighborRoom) where room.exits[direction]?.toRoom() == neighborRoom:
                        shouldFill = true
                    case let .passage(passageAxis) where passageAxis == axis:
                        shouldFill = true
                    default:
                        shouldFill = false
                    }
                    if shouldFill {
                        for fillCoordinate in fillRange {
                            var position = oldPosition
                            position.set(axis: axis, value: fillCoordinate)
                            mapElementsByPosition[position] = fillElement
                        }
                    }
                }
            case .passage(axis):
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
        let minX = range.from.x
        let minY = range.from.y
        //let minPlane = planeRange.lowerBound

        let elementWidth = 6 //14

        var result = ""
        for plane in rangesByPlane.keys.sorted() {
            if !result.isEmpty {
                result += "\n"
            }
            result += "Plane \(plane):\n"
            
            let fillLine = [String](repeating: " ".padding(toLength: elementWidth, withPad: " ", startingAt: 0), count: range.to.x - range.from.x + 1)
            var grid = [[String]](repeating: fillLine, count: range.to.y - range.from.y + 1)

            for (position, element) in mapElementsByPosition {
                guard position.plane == plane else { continue }
                let atX = position.x - minX
                let atY = position.y - minY
                switch element {
                case .room(let room):
                    grid[atY][atX] = String(room.vnum).padding(toLength: elementWidth, withPad: " ", startingAt: 0)
                case .passage(let axis):
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
                result.append(" || \(minY + index)")
            }
        }

        return result
    }
}
