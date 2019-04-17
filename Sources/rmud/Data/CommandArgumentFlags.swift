import Foundation

struct CommandArgumentFlags {
    struct What: OptionSet {
        typealias T = What
    
        let rawValue: UInt8

        static let item         = T(rawValue: 1 << 0)
        static let creature     = T(rawValue: 1 << 1)
        // FIXME: maybe belongs to Extra?
        static let beacon       = T(rawValue: 1 << 2) // монстры только с флагом МАЯК
        // FIXME: maybe belongs to Extra?
        static let noMobile     = T(rawValue: 1 << 3) // цель не может быть монстром
        static let word         = T(rawValue: 1 << 4)
        static let restOfString = T(rawValue: 1 << 5)
        static let many         = T(rawValue: 1 << 6)
    }
    
    struct Where: OptionSet {
        typealias T = Where

        let rawValue: UInt8

        static let equipment  = T(rawValue: 1 << 0)
        static let inventory  = T(rawValue: 1 << 1)
        static let room       = T(rawValue: 1 << 2)
        static let world      = T(rawValue: 1 << 3)
    }
}
