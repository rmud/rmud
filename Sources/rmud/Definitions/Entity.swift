import Foundation

public class Entity {
    private var lastAddedIndex = 0
    
    // Key is "structure name"."field name"[index]:
    // struct.name[0]
    // Index should be omitted for top level fields.
    private var valuesByLowercasedName = [String: Value]()
    private(set) var orderedLowercasedNames = [String]()
    
    private var touchedValues: Set<String> = []
    var isMigrationNeeded = false
    
    var lastStructureIndex = [String: Int]()
    var startLine = 0

    // name is struct.field[index]
    func add(name: String, value: Value) -> Bool {
        let lowercasedName = name.lowercased()
        guard valuesByLowercasedName[lowercasedName] == nil else { return false }
        valuesByLowercasedName[lowercasedName] = value
        orderedLowercasedNames.append(lowercasedName)
        return true
    }
    
    // name is struct.field[index]
    func replace(name: String, value: Value) {
        let lowercasedName = name.lowercased()
        guard valuesByLowercasedName[lowercasedName] == nil else {
            valuesByLowercasedName[lowercasedName] = value
            return
        }
        valuesByLowercasedName[lowercasedName] = value
        orderedLowercasedNames.append(lowercasedName)
    }

    // name is struct.field[index]
// Doesn't work with arrays
//    func remove(name: String) {
//        let lowercasedName = name.lowercased()
//        valuesByLowercasedName.removeValue(forKey: lowercasedName)
//        orderedLowercasedNames = orderedLowercasedNames.filter { $0 != lowercasedName }
//        touchedValues.remove(name)
//    }

    // name is struct.field[index]
    func value(named name: String, touch: Bool) -> Value? {
        let lowercasedName = name.lowercased()
        if touch {
            self.touch(name)
        }
        return valuesByLowercasedName[lowercasedName]
    }
    
    subscript(_ name: String) -> Value? {
        let lowercasedName = name.lowercased()
        touch(lowercasedName)
        return valuesByLowercasedName[lowercasedName]
    }

    subscript(_ name: String, _ index: Int) -> Value? {
        let nameWithIndex = appendIndex(toName: name.lowercased(), index: index)
        touch(nameWithIndex)
        return valuesByLowercasedName[nameWithIndex]
    }

    // name is struct.field WITHOUT [index] suffix
    func hasRequiredField(lowercasedName: String) -> Bool {
        if let structureName = structureName(fromFieldName: lowercasedName) {
            guard let lastIndex = lastStructureIndex[structureName] else {
                // This is a structure field, but no structures were created
                return true
            }
            // Every structure should have required field:
            for i in 0...lastIndex {
                let nameWithIndex = appendIndex(toName: lowercasedName, index: i)
                guard valuesByLowercasedName[nameWithIndex] != nil else { return false }
            }
            return true
        }
        
        return valuesByLowercasedName[lowercasedName] != nil
    }
    
    func structureIndexes(_ name: String) -> CountableRange<Int> {
        if let lastIndex = lastStructureIndex[name] {
            return 0..<(lastIndex + 1)
        }
        return 0..<0
    }
    
    func forEach(_ name: String, do completion: (_ i: Int, _ stop: inout Bool) -> ()) {
        if let lastIndex = lastStructureIndex[name] {
            var stop = false
            for i in 0...lastIndex {
                completion(i, &stop)
                guard !stop else { break }
            }
        }
    }
    
    func logUntouchedFields(comment: String, what: String) {
        let untouchedFields = Set(valuesByLowercasedName.keys).subtracting(touchedValues)
        for field in untouchedFields {
            if !what.isEmpty {
                logWarning("\(comment): \(what): \(field)".capitalizingFirstLetter())
            } else {
                logWarning("\(comment): \(field)".capitalizingFirstLetter())
            }
        }
    }
    
    func untouchAllFields() {
        touchedValues.removeAll()
    }
    
    private func touch(_ name: String) {
        //guard settings.debugLogUnusedEntityFields else { return }
        touchedValues.insert(name)
    }
}
