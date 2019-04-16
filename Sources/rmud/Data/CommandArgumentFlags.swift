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
        
        // Use Extra.oneOrMore instead in command interpreter.
        // FIXME: This enumeration is used in spell definitions, so can't be removed yet
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

    struct Extra: OptionSet {
        typealias T = Extra

        let rawValue: UInt8

        // Other
        // If set, parser will pass FULL argument, typed in by user to ACMD function as parg1 (or parg2)
        //static let passFullArgument = T(rawValue: 1 << 0)
        // Allow specifying multiple targets
        static let oneOrMore = T(rawValue: 1 << 0)
        // Don't handle "object not found" - just pass NULL pointer to ACMD
        static let optional = T(rawValue: 1 << 1)
        // Don't check visibility
        static let notOnlyVisible = T(rawValue: 1 << 2)
        // Add to list only if footmarks of this char are present in room
        static let withFootmarks = T(rawValue: 1 << 3)
        // Perfom careful tracking. For use with A_TRK only
        static let carefulTracking = T(rawValue: 1 << 4)
        // Allow fill words while parsing argument
        //static let allowFillWords = T(rawValue: 1 << 5)
    }
}
