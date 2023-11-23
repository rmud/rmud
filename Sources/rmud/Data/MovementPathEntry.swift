import Foundation

enum MovementReason {
    case move
    case follow
}

struct MovementPathEntry {
    let direction: Direction
    let reason: MovementReason
}
