import Foundation

class FieldInfo {
    let lowercasedName: String
    let type: FieldType
    var flags: FieldFlags
    
    init(lowercasedName: String, type: FieldType, flags: FieldFlags) {
        self.lowercasedName = lowercasedName
        self.type = type
        self.flags = flags
    }
}
