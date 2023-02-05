import Foundation

class Format {
    static func leftPaddedVnum(_ vnum: Int?) -> String {
        let vnumString = vnum != nil ? String(vnum!) : ""
        return vnumString.leftExpandingTo(6)
    }
}
