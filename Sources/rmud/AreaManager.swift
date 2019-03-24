import Foundation

class AreaManager {
    static let sharedInstance = AreaManager()

    var areasByLowercasedName: [String: Area] = [:]
    var areasByStartingVnum: [Int: Area] = [:]
    var areasInResetOrder: [Area] = []
    
    init() {
    }
    
    func createAreas() { // FIXME: use real AreaPrototype
        let keys = db.areaEntitiesByLowercasedName.keys.sorted()
        for areaLowercasedName in keys {
            guard let areaPrototype = db.areaPrototypesByLowercasedName[areaLowercasedName] else { continue }
            guard let area = Area(prototype: areaPrototype) else {
                logFatal("Unable to create area \(areaLowercasedName)")
            }
            guard !area.lowercasedName.isEmpty else {
                logFatal("Area name not set, starting vnum: \(area.vnumRange.lowerBound)")
            }
            guard areasByLowercasedName[area.lowercasedName] == nil else {
                logFatal("Area with this name already exists: \(area.lowercasedName)")
            }
            guard !existingAreasOverlap(with: area) else {
                logFatal("Area overlaps with other areas: \(area.lowercasedName)")
            }
            areasByLowercasedName[area.lowercasedName] = area
            areasByStartingVnum[area.vnumRange.lowerBound] = area
            areasInResetOrder = areasByLowercasedName.sorted { $0.key < $1.key }.map { $1 }
        }
    }
    
    func createRooms() {
        for area in areasInResetOrder {
            area.createRooms()
        }
    }
    
    func buildAreaMaps() {
        for area in areasInResetOrder {
            area.buildMap()
            let rooms = area.findUnlinkedRooms()
            if !rooms.isEmpty {
                let vnums = rooms.map { String($0.vnum) }
                let vnumsString = vnums.joined(separator: ", ")
                logWarning("Area '\(area.lowercasedName)' has rooms not linked anywhere: \(vnumsString)")
            }
        }
    }
    
    func resetAreas() {
        for area in areasInResetOrder {
            area.reset()
        }
    }
    
    private func existingAreasOverlap(with area: Area) -> Bool {
        for existingArea in areasInResetOrder {
            if existingArea.vnumRange.overlaps(area.vnumRange) {
                return true
            }
        }
        return false
    }
    
    func save(area: Area) {
        db.save(areaNamed: area.lowercasedName, prototype: area.prototype)
    }
    
    func findArea(byAbbreviatedName name: String) -> Area? {
        let lowercased = name.lowercased()
        
        // Prefer exact match
        if let area = areasByLowercasedName[lowercased] {
            return area
        }
        
        // No luck, try abbreviations
        for (name, area) in areasByLowercasedName {
            if lowercased.isAbbreviation(of: name, caseInsensitive: true) {
                return area
            }
        }
        return nil
    }
}
