import Foundation

enum AreaMapElement {
    case room(Room)
    case passage(AreaMapPosition.Axis, toRoom: Room, fromRoom: Room)
}
