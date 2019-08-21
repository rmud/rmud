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
                if let destination = room.exitDestination(.north) {
                    mapsByPlane[plane]![y - 1].replaceSubrange(x..<(x + T.roomWidth),
                                                               with: renderedPassage(.vertical, exitDestination: destination, isExploredRoom: isExploredRoom))
                }
                if let destination = room.exitDestination(.east) {
                    // Assigning single char for optimization, because it's known that horizontal
                    // renderings of passages can't be wider
                    mapsByPlane[plane]![y][x + T.roomWidth] =
                        renderedPassage(.horizontal, exitDestination: destination, isExploredRoom: isExploredRoom).first!
                }
                if let destination = room.exitDestination(.south) {
                    mapsByPlane[plane]![y + T.roomHeight].replaceSubrange(x..<(x + T.roomWidth),
                                                                          with: renderedPassage(.vertical, exitDestination: destination, isExploredRoom: isExploredRoom))
                }
                if let destination = room.exitDestination(.west) {
                    mapsByPlane[plane]![y][x - 1] =
                        renderedPassage(.horizontal, exitDestination: destination, isExploredRoom: isExploredRoom).first!
                }
                if let legend = room.legend {
                    if legend.symbol != RoomLegend.defaultSymbol {
                        mapsByPlane[plane]![y][x + T.roomWidth / 2] = ColoredCharacter(legend.symbol, isExploredRoom ? Ansi.nYel : Ansi.bGra)
                    }
                    // Otherwise will be drawn later, autogenerated symbols are not computed yet
                } else {
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
                        mapsByPlane[plane]![y][x + T.roomWidth / 2] =
                            renderedPassage(.upDown, exitDestination: destination, isExploredRoom: isExploredRoom).first!
                    } else if let destination = upDestinationOrNil {
                        mapsByPlane[plane]![y][x + T.roomWidth / 2] =
                            renderedPassage(.up, exitDestination: destination, isExploredRoom: isExploredRoom).first!
                    } else if let destination = downDestinationOrNil {
                        mapsByPlane[plane]![y][x + T.roomWidth / 2] =
                            renderedPassage(.down, exitDestination: destination, isExploredRoom: isExploredRoom).first!
                    }
                }
            case let .passage(axis, toRoom, fromRoom):
                let isExploredRoom = self.isExploredRoom(vnum: toRoom.vnum) && self.isExploredRoom(vnum: fromRoom.vnum)
                guard isExploredRoom == (elementTypes == .explored) else { break }
                
                switch axis {
                case .x:
                    mapsByPlane[plane]![y].replaceSubrange(x..<(x + T.roomWidth), with: T.longXPassage)
                    mapsByPlane[plane]![y][x + T.roomWidth] = T.xPassage.first!
                case .y:
                    let yPassage = [T.fillCharacter, ColoredCharacter("|", isExploredRoom ? Ansi.nNrm : Ansi.bGra), T.fillCharacter]
                    mapsByPlane[plane]![y - 1].replaceSubrange(x..<(x + T.roomWidth), with: yPassage)
                    mapsByPlane[plane]![y].replaceSubrange(x..<(x + T.roomWidth), with: yPassage)
                    mapsByPlane[plane]![y + T.roomHeight].replaceSubrange(x..<(x + T.roomWidth), with: yPassage)
                case .plane:
                    mapsByPlane[plane]![y].replaceSubrange(x..<(x + T.roomWidth), with: T.longZPassage)
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
        
    private func renderedPassage(_ passage: RenderedPassage, exitDestination: Room.ExitDestination, isExploredRoom: Bool) -> [ColoredCharacter] {
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
        if !isExploredRoom {
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
