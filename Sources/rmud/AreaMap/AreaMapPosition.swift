import Foundation

struct AreaMapPosition: Hashable, Equatable {
    enum Axis {
        init(_ direction: Direction) {
            switch direction {
            case .north: self = .y
            case .south: self = .y
            case .east: self = .x
            case .west: self =  .x
            case .up: self = .plane
            case .down: self = .plane
            }
        }
        case x, y, plane
        static func axes() -> [Axis] {
            return [.x, .y, .plane]
        }

        static func axes(excluding axisToExclude: Axis) -> [Axis] {
            switch axisToExclude {
            case .x: return [.y, .plane]
            case .y: return [.x, .plane]
            case .plane: return [.x, .y]
            }
        }
    }

    var x: Int
    var y: Int
    var plane: Int

    init(_ x: Int = 0, _ y: Int = 0, _ plane: Int = 0) {
        self.x = x
        self.y = y
        self.plane = plane
    }

    init(_ direction: Direction, _ distance: Int) {
        switch direction {
        case .north: self.init(.y, -distance)
        case .south: self.init(.y, distance)
        case .west: self.init(.x, -distance)
        case .east: self.init(.x, distance)
        case .down: self.init(.plane, -distance)
        case .up: self.init(.plane, distance)
        }
    }

    init(_ axis: Axis, _ value: Int) {
        switch (axis) {
        case .x: self.init(value, 0, 0)
        case .y: self.init(0, value, 0)
        case .plane: self.init(0, 0, value)
        }
    }

    func direction(axis: Axis) -> Direction? {
        switch axis {
        case .x:
            if self.x > 0 {
                return .east
            } else if (self.x < 0) {
                return .west
            }
        case .y:
            if self.y > 0 {
                return .south
            } else if self.y < 0 {
                return .north
            }
        case .plane:
            if self.plane > 0 {
                return .up
            } else if self.plane < 0 {
                return .down
            }
        }
        return nil
    }

    func get(axis: Axis) -> Int {
        switch axis {
        case .x: return self.x
        case .y: return self.y
        case .plane: return self.plane
        }
    }

    mutating func set(axis: Axis, value: Int) {
        switch axis {
        case .x: self.x = value
        case .y: self.y = value
        case .plane: self.plane = value
        }
    }

    func adjustedBy(x: Int) -> AreaMapPosition {
        return AreaMapPosition(self.x + x, y, plane)
    }

    func adjustedBy(y: Int) -> AreaMapPosition {
        return AreaMapPosition(x, self.y + y, plane)
    }

    func adjustedBy(plane: Int) -> AreaMapPosition {
        return AreaMapPosition(x, y, self.plane + plane)
    }

    func isOnSameLine(as position: AreaMapPosition, axis: Axis) -> Bool {
        for otherAxis in Axis.axes(excluding: axis) {
            guard get(axis: otherAxis) == position.get(axis: otherAxis) else { return false }
        }
        return true
    }

    static func ==(lhs: AreaMapPosition, rhs: AreaMapPosition) -> Bool {
        return lhs.plane == rhs.plane &&
            lhs.x == rhs.x && lhs.y == rhs.y
    }

    public var hashValue: Int { return combinedHash(x, y, plane) }
}

func +(left: AreaMapPosition, right: AreaMapPosition) -> AreaMapPosition {
    return AreaMapPosition(left.x + right.x, left.y + right.y, left.plane + right.plane)
}

func -(left: AreaMapPosition, right: AreaMapPosition) -> AreaMapPosition {
    return AreaMapPosition(left.x - right.x, left.y - right.y, left.plane - right.plane)
}

func +=(left: inout AreaMapPosition, right: AreaMapPosition) {
    left = left + right
}

func -=(left: inout AreaMapPosition, right: AreaMapPosition) {
    left = left - right
}

func lowerBound(_ one: AreaMapPosition, _ other: AreaMapPosition) -> AreaMapPosition {
    return AreaMapPosition(min(one.x, other.x), min(one.y, other.y), min(one.plane, other.plane))
}

func upperBound(_ one: AreaMapPosition, _ other: AreaMapPosition) -> AreaMapPosition {
    return AreaMapPosition(max(one.x, other.x), max(one.y, other.y), max(one.plane, other.plane))
}
