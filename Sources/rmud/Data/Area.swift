import Foundation

class Area {
    let prototype: AreaPrototype
    var lowercasedName: String
    var description: String
    var resetCondition: AreaResetCondition = .never
    var resetInterval: Int = 30
    var age: Int = 0
    var vnumRange: ClosedRange<Int>
    var originVnum: Int?
    var paths: [String: Set<Int>] { prototype.paths }
    
    var rooms: [Room] = []
    var map = AreaMap()
    
    init?(prototype: AreaPrototype) {
        self.prototype = prototype
        
        lowercasedName = prototype.lowercasedName
        vnumRange = prototype.vnumRange
        
        description = prototype.description ?? "Без описания"
        resetCondition = prototype.resetCondition ?? resetCondition
        resetInterval = prototype.resetInterval ?? resetInterval
        originVnum = prototype.originVnum
    }
}

extension Area: Equatable {
    public static func ==(lhs: Area, rhs: Area) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension Area: Hashable {
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}

