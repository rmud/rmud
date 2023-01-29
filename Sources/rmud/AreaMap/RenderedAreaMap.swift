import Foundation

class RenderedAreaMap {
    typealias T = RenderedAreaMap

    enum ExploredRooms {
        case all
        case some(Set<Int>)
    }
    
    struct RenderConfiguration {
        let exploredRooms: ExploredRooms
        let showUnexploredRooms: Bool
        let highlightedRooms: Set<Int>
        let markedRooms: Set<Int>
    }
    
    struct RoomLegendWithMetadata {
        var finalLegend: RoomLegend
        var room: Room
    }
    
    enum RenderedPassage {
        case horizontal
        case vertical
        case up
        case down
        case upDown
    }
    
    enum ElementType {
        case unexplored
        case explored
    }

    static let fillCharacter = ColoredCharacter(".", Ansi.nBlu)
    
    // Passages
    static let xPassage = ColoredCharacter("-")
    static let xPassageUnexplored = ColoredCharacter("-", Ansi.bGra)
    static let yPassage = ColoredCharacter("|")
    static let yPassageUnexplored = ColoredCharacter("|", Ansi.bGra)
    
    // Room / long passage
    //static let room = [ColoredCharacter]("( )")
    static let longXPassage = [ColoredCharacter]("---")
    static let longXPassageUnexplored = [ColoredCharacter]("---", Ansi.bGra)
    static let longZPassage = [ColoredCharacter](" * ")
    static let longZPassageUnexplored = [ColoredCharacter](" * ", Ansi.bGra)
    
    // Middle room marks
    static let up = ColoredCharacter("^")
    static let upUnexplored = ColoredCharacter("^", Ansi.bGra)
    static let down = ColoredCharacter("v")
    static let downUnexplored = ColoredCharacter("v", Ansi.bGra)
    static let upDown = ColoredCharacter("%")
    static let upDownUnexplored = ColoredCharacter("%", Ansi.bGra)
    
    typealias MapsByPlane = [/* Plane */ Int: /* Plane map */ [[ColoredCharacter]]]

    let areaMap: AreaMap
    let configuration: RenderConfiguration
    
    var planes: MapsByPlane.Keys {
        return mapsByPlane.keys
    }
    
    private var roomsWithLegends = Set<Room>()
    var roomLegends: [RoomLegendWithMetadata] = []
    
    private var mapsByPlane = MapsByPlane()
    private var renderedRoomCentersByRoom = [Room: AreaMapPosition]() // AreaMapPosition is used here only for convenience, its x and y specify room center offset in characters relative to top-left corner of the rendered map
    
    static let roomWidth = 3
    static let roomHeight = 1
    static let roomSpacingWidth = 1
    static let roomSpacingHeight = 1

    // Extra space to draw room exits near the map border
    static let horizontalPadding = 1
    static let verticalPadding = 1

    init(areaMap: AreaMap, renderConfiguration: RenderConfiguration) {
        self.areaMap = areaMap
        self.configuration = renderConfiguration
        render()
    }

    public func plane(forRoom room: Room) -> Int? {
        return renderedRoomCentersByRoom[room]?.plane
    }

    public func planeSizeInCharacters() -> (width: Int, height: Int) {
        let logicalWidth = areaMap.range.size(axis: .x)
        let logicalHeight = areaMap.range.size(axis: .y)
        let width = T.roomWidth * logicalWidth + T.roomSpacingWidth * (logicalWidth - 1) + 2 * T.horizontalPadding
        let height = T.roomHeight * logicalHeight + T.roomSpacingHeight * (logicalHeight - 1) + 2 * T.verticalPadding
        return (width: width, height: height)
    }

    public func fragment(near room: Room, playerRoom: Room? = nil, horizontalRooms: Int, verticalRooms: Int) -> [[ColoredCharacter]] {

        guard let roomCenter = renderedRoomCentersByRoom[room] else { return [] }

        let widthInCharacters = T.roomWidth * horizontalRooms + T.roomSpacingWidth * (horizontalRooms + 1)
        let heightInCharacters = T.roomHeight * verticalRooms + T.roomSpacingHeight * (verticalRooms + 1)

        let topLeftHalf = AreaMapPosition(widthInCharacters / 2, heightInCharacters / 2, 0)
        let from = roomCenter - topLeftHalf

        return fragment(plane: roomCenter.plane, x: from.x, y: from.y, widthInCharacters: widthInCharacters, heightInCharacters: heightInCharacters, playerRoom: playerRoom, pad: true)
    }

    public func fragment(wholePlane plane: Int, playerRoom: Room? = nil) -> [[ColoredCharacter]] {

        let size = planeSizeInCharacters()

        return fragment(plane: plane, x: 0, y: 0, widthInCharacters: size.width, heightInCharacters: size.height, playerRoom: playerRoom, pad: true)
    }

    public func fragment(plane: Int, x: Int, y: Int, widthInCharacters: Int, heightInCharacters: Int, playerRoom: Room? = nil, pad: Bool) -> [[ColoredCharacter]] {

        guard let map = mapsByPlane[plane] else { return [] }
        guard map.count > 0 && map[0].count > 0 else { return [] }

        let mapRange = AreaMapRange(from: AreaMapPosition(0, 0, plane), toInclusive: AreaMapPosition(map[0].count, map.count, plane))

        let fromPosition = AreaMapPosition(x, y, 0)
        let toPosition = AreaMapPosition(x + widthInCharacters, y + heightInCharacters, 0)

        let from = pad
            ? fromPosition
            : upperBound(fromPosition, mapRange.from)
        let toInclusive = pad
            ? toPosition
            : lowerBound(toPosition, mapRange.toInclusive)

        let topLeftPadding = upperBound(mapRange.from - from, AreaMapPosition(0, 0, 0))
        let bottomRightPadding = upperBound(toInclusive - mapRange.toInclusive, AreaMapPosition(0, 0, 0))

        var fragmentLines = [[ColoredCharacter]]()

        let playerRoomCenter = playerRoom != nil
            ? renderedRoomCentersByRoom[playerRoom!]
            : nil
        for y in from.y..<toInclusive.y {
            guard y - from.y >= topLeftPadding.y && toInclusive.y - y - 1 >= bottomRightPadding.y else {
                let line = [ColoredCharacter](repeating: T.fillCharacter, count: toInclusive.x - from.x)
                fragmentLines.append(line)
                continue
            }

            var line = [ColoredCharacter]()
            //line.reserveCapacity(to.x - from.x) // take color into account too

            line += [ColoredCharacter](repeating: T.fillCharacter, count: topLeftPadding.x)
            line += map[y][from.x + topLeftPadding.x..<toInclusive.x - bottomRightPadding.x]
            line += [ColoredCharacter](repeating: T.fillCharacter, count: bottomRightPadding.x)

            if let playerRoomCenter = playerRoomCenter,
                    playerRoomCenter.plane == plane && playerRoomCenter.y == y {
                if configuration.highlightedRooms.isEmpty {
                    // If no specific rooms were requested to be highlighted, highlight player's room
                    let leftBracketPosition = playerRoomCenter.x - T.roomWidth / 2
                    let rightBracketPosition = playerRoomCenter.x + T.roomWidth / 2
                    if leftBracketPosition >= from.x && rightBracketPosition < toInclusive.x {
                        line[leftBracketPosition - from.x] = ColoredCharacter("[", Ansi.bGrn)
                    }
                    if rightBracketPosition >= from.x && rightBracketPosition < toInclusive.x {
                        line[rightBracketPosition - from.x] = ColoredCharacter("]", Ansi.bGrn)
                    }
                } else {
                    if configuration.markedRooms.isEmpty {
                        // Otherwise, highlight requested rooms, and use player's marker inside of the room
                        line[playerRoomCenter.x] = ColoredCharacter("*", Ansi.bGrn)
                    }
                }
            }

            fragmentLines.append(line)
        }
        
        return fragmentLines
    }

    private func render() {
        mapsByPlane.removeAll()
        
        for (plane, _) in areaMap.rangesByPlane {
            let size = planeSizeInCharacters()
            let renderedEmptyRow = [ColoredCharacter](repeating: T.fillCharacter, count: size.width)
            mapsByPlane[plane] = [[ColoredCharacter]](repeating: renderedEmptyRow, count: size.height)
        }
        
        if configuration.showUnexploredRooms {
            drawMapElements(elementTypes: .unexplored)
        }
        
        drawMapElements(elementTypes: .explored)
        
        autogenerateAndDrawRemainingLegendSymbols()
        drawMarkedRooms()
    }
    
    private func drawMapElements(elementTypes: ElementType) {
        let mapRange = areaMap.range

        for (position, element) in areaMap.mapElementsByPosition {
            let plane = position.plane
            guard mapsByPlane[plane] != nil else { continue }
            
            let x = T.horizontalPadding + (T.roomWidth + T.roomSpacingWidth) * (position.x - mapRange.from.x)
            let y = T.verticalPadding + (T.roomHeight + T.roomSpacingHeight) * (position.y - mapRange.from.y)
            
            switch element {
            case .room(let room):
                let isExploredRoom = self.isExploredRoom(vnum: room.vnum)
                guard isExploredRoom == (elementTypes == .explored) else { break }
                
                if room.legend != nil {
                    roomsWithLegends.insert(room)
                }
                
                renderedRoomCentersByRoom[room] = AreaMapPosition(x + T.roomWidth / 2, y, plane)
                let roomColor: String
                if configuration.highlightedRooms.contains(room.vnum) {
                    roomColor = Ansi.bMag
                } else if isExploredRoom {
                    roomColor = Ansi.nNrm
                } else {
                    roomColor = Ansi.bGra
                }
                mapsByPlane[plane]![y].replaceSubrange(x..<(x + T.roomWidth), with: [ColoredCharacter]("( )", roomColor))
                if let (destination, toRoom) = room.exitDestination(.north) {
                    let isExplored = isExploredRoom && self.isExploredRoom(toRoom)
                    mapsByPlane[plane]![y - 1].replaceSubrange(x..<(x + T.roomWidth),
                                                               with: renderedPassage(.vertical, exitDestination: destination, isExplored: isExplored))
                }
                if let (destination, toRoom) = room.exitDestination(.east) {
                    let isExplored = isExploredRoom && self.isExploredRoom(toRoom)
                    // Assigning single char for optimization, because it's known that horizontal
                    // renderings of passages can't be wider
                    mapsByPlane[plane]![y][x + T.roomWidth] =
                        renderedPassage(.horizontal, exitDestination: destination, isExplored: isExplored).first!
                }
                if let (destination, toRoom) = room.exitDestination(.south) {
                    let isExplored = isExploredRoom && self.isExploredRoom(toRoom)
                    mapsByPlane[plane]![y + T.roomHeight].replaceSubrange(x..<(x + T.roomWidth),
                                                                          with: renderedPassage(.vertical, exitDestination: destination, isExplored: isExplored))
                }
                if let (destination, toRoom) = room.exitDestination(.west) {
                    let isExplored = isExploredRoom && self.isExploredRoom(toRoom)
                    mapsByPlane[plane]![y][x - 1] =
                        renderedPassage(.horizontal, exitDestination: destination, isExplored: isExplored).first!
                }
                if let legend = room.legend {
                    if legend.symbol != RoomLegend.defaultSymbol {
                        mapsByPlane[plane]![y][x + T.roomWidth / 2] = ColoredCharacter(legend.symbol, isExploredRoom ? Ansi.nYel : Ansi.bGra)
                    }
                    // Otherwise will be drawn later, autogenerated symbols are not computed yet
                } else {
                    let upDestinationOrNil = room.exitDestination(.up)
                    let downDestinationOrNil = room.exitDestination(.down)
                    if let (upDestination, upToRoom) = upDestinationOrNil, let (downDestination, downToRoom) = downDestinationOrNil {
                        let destination: ExitDestination
                        if upDestination == .invalid || downDestination == .invalid {
                            destination = .invalid
                        } else if upDestination == .toAnotherArea || downDestination == .toAnotherArea {
                            destination = .toAnotherArea
                        } else {
                            destination = .insideArea
                        }
                        let isExplored = isExploredRoom && self.isExploredRoom(upToRoom) && self.isExploredRoom(downToRoom)
                        mapsByPlane[plane]![y][x + T.roomWidth / 2] =
                        renderedPassage(.upDown, exitDestination: destination, isExplored: isExplored).first!
                    } else if let (destination, room) = upDestinationOrNil {
                        let isExplored = isExploredRoom && self.isExploredRoom(room)
                        mapsByPlane[plane]![y][x + T.roomWidth / 2] =
                            renderedPassage(.up, exitDestination: destination, isExplored: isExplored).first!
                    } else if let (destination, room) = downDestinationOrNil {
                        let isExplored = isExploredRoom && self.isExploredRoom(room)
                        mapsByPlane[plane]![y][x + T.roomWidth / 2] =
                            renderedPassage(.down, exitDestination: destination, isExplored: isExplored).first!
                    }
                }
            case let .passage(axis, toRoom, fromRoom):
                let isExplored = self.isExploredRoom(vnum: toRoom.vnum) && self.isExploredRoom(vnum: fromRoom.vnum)
                guard isExplored == (elementTypes == .explored) else { break }
                
                switch axis {
                case .x:
                    mapsByPlane[plane]![y].replaceSubrange(x..<(x + T.roomWidth), with: isExplored ? T.longXPassage : T.longXPassageUnexplored)
                    mapsByPlane[plane]![y][x + T.roomWidth] = isExplored ? T.xPassage : T.xPassageUnexplored
                case .y:
                    let yPassage = [T.fillCharacter, isExplored ? T.yPassage : T.yPassageUnexplored, T.fillCharacter]
                    mapsByPlane[plane]![y - 1].replaceSubrange(x..<(x + T.roomWidth), with: yPassage)
                    mapsByPlane[plane]![y].replaceSubrange(x..<(x + T.roomWidth), with: yPassage)
                    mapsByPlane[plane]![y + T.roomHeight].replaceSubrange(x..<(x + T.roomWidth), with: yPassage)
                case .plane:
                    mapsByPlane[plane]![y].replaceSubrange(x..<(x + T.roomWidth), with: isExplored ? T.longZPassage : T.longZPassageUnexplored)
                }
            }
        }
    }
    
    private func autogenerateAndDrawRemainingLegendSymbols() {
        var autogeneratedIndex = 0
        roomLegends = roomsWithLegends.sorted { room1, room2 in
            let rc1 = renderedRoomCentersByRoom[room1]!
            let rc2 = renderedRoomCentersByRoom[room2]!
            return rc1.plane > rc2.plane ||
                (rc1.plane == rc2.plane && rc1.y < rc2.y) ||
                (rc1.plane == rc2.plane && rc1.y == rc2.y && rc1.x < rc2.x)
        }.map { room in
            var legend = room.legend!
            if legend.name.isEmpty {
                legend.name = room.name
            }
            if legend.symbol != RoomLegend.defaultSymbol {
                return RoomLegendWithMetadata(finalLegend: legend, room: room)
            }
            legend.symbol = RoomLegend.symbolFromIndex(autogeneratedIndex)
            autogeneratedIndex += 1

            let rc = renderedRoomCentersByRoom[room]!
            let isExploredRoom = self.isExploredRoom(vnum: room.vnum)
            mapsByPlane[rc.plane]![rc.y][rc.x] = ColoredCharacter(legend.symbol, isExploredRoom ? Ansi.nYel : Ansi.bGra)

            return RoomLegendWithMetadata(finalLegend: legend, room: room)
        }
    }
    
    private func drawMarkedRooms() {
        for roomVnum in configuration.markedRooms {
            guard let room = db.roomsByVnum[roomVnum] else { continue }
            guard let rc = renderedRoomCentersByRoom[room] else { continue }
            mapsByPlane[rc.plane]![rc.y][rc.x] = ColoredCharacter("*", Ansi.bCyn)
        }
    }
    
    private func isExploredRoom(vnum: Int) -> Bool {
        if case .some(let vnums) = configuration.exploredRooms {
            return vnums.contains(vnum)
        }
        return true
    }
    
    private func isExploredRoom(_ room: Room?) -> Bool {
        guard let room = room else { return true }
        return isExploredRoom(vnum: room.vnum)
    }
        
    private func renderedPassage(_ passage: RenderedPassage, exitDestination: ExitDestination, isExplored: Bool) -> [ColoredCharacter] {
        var result: [ColoredCharacter]

        switch passage {
        case .horizontal:
            result = [isExplored ? T.xPassage : T.xPassageUnexplored]
        case .vertical:
            result = [T.fillCharacter, isExplored ? T.yPassage : T.yPassageUnexplored, T.fillCharacter]
        case .up:
            result = [isExplored ? T.up : T.upUnexplored]
        case .down:
            result = [isExplored ? T.down : T.downUnexplored]
        case .upDown:
            result = [isExplored ? T.upDown : T.upDownUnexplored]
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
