import Foundation

class RenderedAreaMap {
    typealias T = RenderedAreaMap

    enum KnownRooms {
        case all
        case some(Set<Int>)
    }
    
    struct RenderConfiguration {
        let knownRooms: KnownRooms
        let showUnknownRooms: Bool
    }
    
    enum RenderedPassage {
        case horizontal
        case vertical
        case up
        case down
        case upDown
    }

    static let fillCharacter = ColoredCharacter(".", Ansi.nBlu)
    
    // Passages
    static let xPassage: [ColoredCharacter] = ["-"]
    //static let yPassage: [ColoredCharacter] = [fillCharacter, "|", fillCharacter]
    
    // Room / long passage
    //static let room = [ColoredCharacter]("( )")
    static let longXPassage = [ColoredCharacter]("---")
    static let longZPassage = [ColoredCharacter](" * ")
    
    // Middle room marks
    static let up = [ColoredCharacter]("^")
    static let down = [ColoredCharacter]("v")
    static let upDown = [ColoredCharacter]("%")
    
    typealias MapsByPlane = [/* Plane */ Int: /* Plane map */ [[ColoredCharacter]]]

    let areaMap: AreaMap
    let configuration: RenderConfiguration
    
    var planes: MapsByPlane.Keys {
        return mapsByPlane.keys
    }
    
    private var mapsByPlane = MapsByPlane()
    private var firstRoomsByPlane = [Int: Room]()
    private var renderedRoomCentersByRoom = [Room: AreaMapPosition]() // AreaMapPosition is used here only for convenience, its x and y specify room center offset in characters relative to top-left corner of the rendered map
    
    let roomWidth = 3
    let roomHeight = 1
    let roomSpacingWidth = 1
    let roomSpacingHeight = 1

    // Extra space to draw room exits near the map border
    let horizontalPadding = 1
    let verticalPadding = 1

    init(areaMap: AreaMap, renderConfiguration: RenderConfiguration) {
        self.areaMap = areaMap
        self.configuration = renderConfiguration
        render()
    }

    public func plane(forRoom room: Room) -> Int? {
        return renderedRoomCentersByRoom[room]?.plane
    }

    public var planeSize: (width: Int, height: Int) {
        let logicalWidth = areaMap.range.size(axis: .x)
        let logicalHeight = areaMap.range.size(axis: .y)
        let width = roomWidth * logicalWidth + roomSpacingWidth * (logicalWidth - 1) + 2 * horizontalPadding
        let height = roomHeight * logicalHeight + roomSpacingHeight * (logicalHeight - 1) + 2 * verticalPadding
        return (width: width, height: height)
    }

    public func fragment(near room: Room, playerRoom: Room? = nil, horizontalRooms: Int, verticalRooms: Int) -> [[ColoredCharacter]] {

        guard let roomCenter = renderedRoomCentersByRoom[room] else { return [] }

        let width = roomWidth * horizontalRooms + roomSpacingWidth * (horizontalRooms + 1)
        let height = roomHeight * verticalRooms + roomSpacingHeight * (verticalRooms + 1)

        let topLeftHalf = AreaMapPosition(width / 2, height / 2, 0)
        let from = roomCenter - topLeftHalf

        return fragment(plane: roomCenter.plane, x: from.x, y: from.y, width: width, height: height, playerRoom: playerRoom, pad: true)
    }

    public func fragment(wholePlane plane: Int, playerRoom: Room? = nil) -> [[ColoredCharacter]] {

        let size = planeSize

        return fragment(plane: plane, x: 0, y: 0, width: size.width, height: size.height, playerRoom: playerRoom, pad: true)
    }

    public func fragment(plane: Int, x: Int, y: Int, width: Int, height: Int, playerRoom: Room? = nil, pad: Bool) -> [[ColoredCharacter]] {

        guard let map = mapsByPlane[plane] else { return [] }
        guard map.count > 0 && map[0].count > 0 else { return [] }

        let mapRange = AreaMapRange(from: AreaMapPosition(0, 0, plane), to: AreaMapPosition(map[0].count, map.count, plane))

        let fromPosition = AreaMapPosition(x, y, 0)
        let toPosition = AreaMapPosition(x + width, y + height, 0)

        let from = pad
            ? fromPosition
            : upperBound(fromPosition, mapRange.from)
        let to = pad
            ? toPosition
            : lowerBound(toPosition, mapRange.to)

        let topLeftPadding = upperBound(mapRange.from - from, AreaMapPosition(0, 0, 0))
        let bottomRightPadding = upperBound(to - mapRange.to, AreaMapPosition(0, 0, 0))

        var fragmentLines = [[ColoredCharacter]]()

        let playerRoomCenter = playerRoom != nil
            ? renderedRoomCentersByRoom[playerRoom!]
            : nil
        for y in from.y..<to.y {
            guard y - from.y >= topLeftPadding.y && to.y - y - 1 >= bottomRightPadding.y else {
                let line = [ColoredCharacter](repeating: T.fillCharacter, count: to.x - from.x)
                fragmentLines.append(line)
                continue
            }

            var line = [ColoredCharacter]()
            //line.reserveCapacity(to.x - from.x) // take color into account too

            line += [ColoredCharacter](repeating: T.fillCharacter, count: topLeftPadding.x)
            line += map[y][from.x + topLeftPadding.x..<to.x - bottomRightPadding.x]
            line += [ColoredCharacter](repeating: T.fillCharacter, count: bottomRightPadding.x)

            if let playerRoomCenter = playerRoomCenter, playerRoomCenter.plane == plane && playerRoomCenter.y == y {
                let leftBracketPosition = playerRoomCenter.x - roomWidth / 2
                let rightBracketPosition = playerRoomCenter.x + roomWidth / 2
                if leftBracketPosition >= from.x && rightBracketPosition < to.x {
                    line[leftBracketPosition - from.x] = ColoredCharacter("[", Ansi.bGrn)
                }
                if rightBracketPosition >= from.x && rightBracketPosition < to.x {
                    line[rightBracketPosition - from.x] = ColoredCharacter("]", Ansi.bGrn)
                }
            }

            fragmentLines.append(line)
        }
        
        return fragmentLines
    }

    func render() {
        mapsByPlane.removeAll()
        firstRoomsByPlane.removeAll()
        
        let mapRange = areaMap.range

        for (plane, _) in areaMap.rangesByPlane {
            let size = planeSize
            let renderedEmptyRow = [ColoredCharacter](repeating: T.fillCharacter, count: size.width)
            mapsByPlane[plane] = [[ColoredCharacter]](repeating: renderedEmptyRow, count: size.height)
        }
        
        for (position, element) in areaMap.mapElementsByPosition {
            let plane = position.plane
            guard mapsByPlane[plane] != nil else { continue }

            let x = horizontalPadding + (roomWidth + roomSpacingWidth) * (position.x - mapRange.from.x)
            let y = verticalPadding + (roomHeight + roomSpacingHeight) * (position.y - mapRange.from.y)

            switch element {
            case .room(let room):
                let isKnownRoom = self.isKnownRoom(vnum: room.vnum)
                guard isKnownRoom || configuration.showUnknownRooms else { break }
                renderedRoomCentersByRoom[room] = AreaMapPosition(x + roomWidth / 2, y, plane)
                firstRoomsByPlane[plane] = room
                mapsByPlane[plane]![y].replaceSubrange(x..<(x + roomWidth), with: [ColoredCharacter]("( )", isKnownRoom ? Ansi.nNrm : Ansi.bGra))
                if let destination = room.exitDestination(.north) {
                    mapsByPlane[plane]![y - 1].replaceSubrange(x..<(x + roomWidth),
                                                               with: renderedPassage(.vertical, exitDestination: destination, isKnownRoom: isKnownRoom))
                }
                if let destination = room.exitDestination(.east) {
                    // Assigning single char for optimization, because it's known that horizontal
                    // renderings of passages can't be wider
                    mapsByPlane[plane]![y][x + roomWidth] =
                        renderedPassage(.horizontal, exitDestination: destination, isKnownRoom: isKnownRoom).first!
                }
                if let destination = room.exitDestination(.south) {
                    mapsByPlane[plane]![y + roomHeight].replaceSubrange(x..<(x + roomWidth),
                        with: renderedPassage(.vertical, exitDestination: destination, isKnownRoom: isKnownRoom))
                }
                if let destination = room.exitDestination(.west) {
                    mapsByPlane[plane]![y][x - 1] =
                        renderedPassage(.horizontal, exitDestination: destination, isKnownRoom: isKnownRoom).first!
                }
                let upDestinationOrNil = room.exitDestination(.up)
                let downDestinationOrNil = room.exitDestination(.down)
                if let upDestination = upDestinationOrNil, let downDestination = downDestinationOrNil {
                    let destination: Room.ExitDestination
                    if upDestination == .invalid || downDestination == .invalid {
                        destination = .invalid
                    } else if upDestination == .toAnotherArea || downDestination == .toAnotherArea {
                        destination = .toAnotherArea
                    } else {
                        destination = .insideArea
                    }
                    let exitVnumUpOrNil = room.exitVnum(.up)
                    let isKnownRoomUp = exitVnumUpOrNil != nil ? self.isKnownRoom(vnum: exitVnumUpOrNil!) : false
                    let exitVnumDownOrNil = room.exitVnum(.down)
                    let isKnownRoomDown = exitVnumDownOrNil != nil ?  self.isKnownRoom(vnum: exitVnumDownOrNil!) : false
                    mapsByPlane[plane]![y][x + roomWidth / 2] =
                        renderedPassage(.upDown, exitDestination: destination, isKnownRoom: isKnownRoom || isKnownRoomUp || isKnownRoomDown).first!
                } else if let destination = upDestinationOrNil {
                    let exitVnumUpOrNil = room.exitVnum(.up)
                    let isKnownRoomUp = exitVnumUpOrNil != nil ? self.isKnownRoom(vnum: exitVnumUpOrNil!) : false
                    mapsByPlane[plane]![y][x + roomWidth / 2] =
                        renderedPassage(.up, exitDestination: destination, isKnownRoom: isKnownRoom || isKnownRoomUp).first!
                } else if let destination = downDestinationOrNil {
                    let exitVnumDownOrNil = room.exitVnum(.down)
                    let isKnownRoomDown = exitVnumDownOrNil != nil ?  self.isKnownRoom(vnum: exitVnumDownOrNil!) : false
                    mapsByPlane[plane]![y][x + roomWidth / 2] =
                        renderedPassage(.down, exitDestination: destination, isKnownRoom: isKnownRoom || isKnownRoomDown).first!
                }
            case let .passage(axis, toRoom, fromRoom):
                let isKnownRoom = self.isKnownRoom(vnum: toRoom.vnum) && self.isKnownRoom(vnum: fromRoom.vnum)
                guard isKnownRoom || configuration.showUnknownRooms else { break }
                switch axis {
                case .x:
                    mapsByPlane[plane]![y].replaceSubrange(x..<(x + roomWidth), with: T.longXPassage)
                    mapsByPlane[plane]![y][x + roomWidth] = T.xPassage.first!
                case .y:
                    let yPassage = [T.fillCharacter, ColoredCharacter("|", isKnownRoom ? Ansi.nNrm : Ansi.bGra), T.fillCharacter]
                    mapsByPlane[plane]![y - 1].replaceSubrange(x..<(x + roomWidth), with: yPassage)
                    mapsByPlane[plane]![y].replaceSubrange(x..<(x + roomWidth), with: yPassage)
                    mapsByPlane[plane]![y + roomHeight].replaceSubrange(x..<(x + roomWidth), with: yPassage)
                case .plane:
                    mapsByPlane[plane]![y].replaceSubrange(x..<(x + roomWidth), with: T.longZPassage)
                }
            }
        }
    }
    
    private func isKnownRoom(vnum: Int) -> Bool {
        if case .some(let vnums) = configuration.knownRooms {
            return vnums.contains(vnum)
        }
        return true
    }
        
    private func renderedPassage(_ passage: RenderedPassage, exitDestination: Room.ExitDestination, isKnownRoom: Bool) -> [ColoredCharacter] {
        var result: [ColoredCharacter]
        switch passage {
            case .horizontal:
                result = T.xPassage
            case .vertical:
                result = [T.fillCharacter, "|", T.fillCharacter]
            case .up:
                result = T.up
            case .down:
                result = T.down
            case .upDown:
                result = T.upDown
        }
        if !isKnownRoom {
            result = result.map {
                $0 == T.fillCharacter ? $0 :
                    ColoredCharacter($0.character, Ansi.bGra)
            }
        }
        switch exitDestination {
            case .insideArea:
                break
            case .toAnotherArea:
                return result.map {
                    $0 == T.fillCharacter ? $0 :
                    ColoredCharacter($0.character, Ansi.nCyn)
                }
            case .invalid:
                return result.map {
                    $0 == T.fillCharacter ? $0 :
                    ColoredCharacter($0.character, Ansi.bRed) }
        }
        return result
    }
}
