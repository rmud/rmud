import Foundation

// FIXME: don't store entities, use during loading then discard after instantiating prototypes
class AreaEntities {
    var areaEntity = Entity()

    var roomEntitiesByVnum = [Int: Entity]()
    var mobileEntitiesByVnum = [Int: Entity]()
    var itemEntitiesByVnum = [Int: Entity]()
}
