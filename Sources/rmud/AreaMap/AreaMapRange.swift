import Foundation

public struct AreaMapRange {
    var from: AreaMapPosition
    var toInclusive: AreaMapPosition

    init(expandedWith position: AreaMapPosition) {
        self.from = position
        self.toInclusive = position
    }

    init(from: AreaMapPosition, toInclusive: AreaMapPosition) {
        self.from = from
        self.toInclusive = toInclusive
    }
    
    var size: AreaMapPosition {
        return toInclusive - from + AreaMapPosition(1, 1, 1)
    }
    
    func size(axis: AreaMapPosition.Axis) -> Int {
        return toInclusive.get(axis: axis) - from.get(axis: axis) + 1
    }
    
    mutating func expand(with position: AreaMapPosition) {
        self.from = lowerBound(self.from, position)
        self.toInclusive = upperBound(self.toInclusive, position)
    }

    func expanded(with position: AreaMapPosition) -> AreaMapRange {
        return AreaMapRange(from: lowerBound(self.from, position), toInclusive: upperBound(self.toInclusive, position))
    }

    mutating func unite(with range: AreaMapRange) {
        self.from = lowerBound(self.from, range.from)
        self.toInclusive = upperBound(self.toInclusive, range.toInclusive)
    }

    func united(with range: AreaMapRange) -> AreaMapRange {
        return AreaMapRange(from: lowerBound(self.from, range.from), toInclusive: upperBound(self.toInclusive, range.toInclusive))
    }

    mutating func shift(by offset: AreaMapPosition) {
        self.from += offset
        self.toInclusive += offset
    }

    func shifted(by offset: AreaMapPosition) -> AreaMapRange {
        return AreaMapRange(from: self.from + offset, toInclusive: self.toInclusive + offset)
    }
}
