import Foundation

struct EventActionFlags: OptionSet {
    typealias T = EventActionFlags
    
    let rawValue: UInt8
    
    static let denyAction =    T(rawValue: 1 << 0) // Cancel the event after showing messages
    
    static let aliases = ["кперехват.выполнение", "мперехват.выполнение", "пперехват.выполнение"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1: "запретить"
        ])
    }
}

