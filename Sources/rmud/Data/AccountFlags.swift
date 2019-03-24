import Foundation

struct AccountFlags: OptionSet {
    typealias T = AccountFlags
    
    let rawValue: UInt8
    
    static let confirmationEmailSent = T(rawValue: 1 << 0)
    static let passwordSet = T(rawValue: 1 << 1)
}

