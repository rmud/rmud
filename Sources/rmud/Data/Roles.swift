import Foundation

struct Roles: OptionSet {
    typealias T = Roles
    
    let rawValue: UInt8

    static let admin = T(rawValue: 1 << 0)
}
