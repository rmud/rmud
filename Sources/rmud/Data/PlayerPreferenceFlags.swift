import Foundation

// Preference flags: used by char_data.plr.T (0-63 bits) 
struct PlayerPreferenceFlags: OptionSet {
    typealias T = PlayerPreferenceFlags
    
    let rawValue: UInt64

    static let brief          = T(rawValue: 1 << 0)  // Room descs won't normally be shown
    static let compact        = T(rawValue: 1 << 1)  // No extra CRLF pair before prompts
    static let deaf           = T(rawValue: 1 << 2)  // Can't hear shouts
    static let busy           = T(rawValue: 1 << 3)  // Can't receive tells
    static let displayHitPointsInPrompt
                              = T(rawValue: 1 << 4)  // Display hit points in prompt (fixme)
    static let listening      = T(rawValue: 1 << 5)  // Listening closely
    static let displayMovementInPrompt
                              = T(rawValue: 1 << 6)  // Display move points in prompt (fixme)
    static let autoexit       = T(rawValue: 1 << 7)  // Display exits in a room (fixme)
    static let godMode        = T(rawValue: 1 << 8)  // Doesn't participate in normal gameplay
    static let hideTeamMovement       = T(rawValue: 1 << 9)  // Do not print team movement messages
    static let rentBank       = T(rawValue: 1 << 10) // Pay rent from bank account first
    static let keepFighting   = T(rawValue: 1 << 11) // Надо ли убегать при обрыве связи
    static let holylight      = T(rawValue: 1 << 12) // Can see everything
    //static let color          = T(rawValue: 1 << 13) // Color
    static let noHighlight    = T(rawValue: 1 << 14) // Don't use highlighting of some words       // -
    static let noPKill        = T(rawValue: 1 << 15) //FIXME крив! Персонаж не участвет в боях с другими персонажами
    // FIXME: make log level a separate variable?
    static let logLevelBit1   = T(rawValue: 1 << 16) // On-line System Log (low bit)
    static let logLevelBit2   = T(rawValue: 1 << 17) // On-line System Log (high bit)
    //static let villain      = T(rawValue: 1 << 18) // ---
    static let fullDirections = T(rawValue: 1 << 19) // не использовать сокращения команд направдлений
    static let autostat       = T(rawValue: 1 << 21) // Can see autostatistics
    static let dispmem        = T(rawValue: 1 << 22) // Display mem time in prompt (fixme)
    static let displayXpInPrompt
                              = T(rawValue: 1 << 23) // Display XP to next level in prompt (fixme)
    static let displayCoinsInPrompt
                              = T(rawValue: 1 << 24) // Display amount of cash in prompt (fixme)
    static let rememorize     = T(rawValue: 1 << 25) // Auto rememorize spells
    static let automapper     = T(rawValue: 1 << 26) // Automapper support
    static let nominative     = T(rawValue: 1 << 27) // Use nominative only for players
    static let training       = T(rawValue: 1 << 28) // Не болучть опыт за смерть монстра
    static let quantity       = T(rawValue: 1 << 29) // Сообщать численность группы после списка
    static let unusedObjvn    = T(rawValue: 1 << 30)
    static let autoexitEng    = T(rawValue: 1 << 31) // Show english autoexits
    static let stackMobiles   = T(rawValue: 1 << 32) // Stack mobs
    static let stackItems     = T(rawValue: 1 << 33) // Stack objs
    static let reply          = T(rawValue: 1 << 34) // Allow to reply when invis
    static let split          = T(rawValue: 1 << 35) // Split any text longest than page_width
    static let displag        = T(rawValue: 1 << 36) // Display lag state in prompt
    static let unusedCurs     = T(rawValue: 1 << 37)
    static let nohpmvWhenMax  = T(rawValue: 1 << 39) // Don't show HP&MV in status when max
    static let map            = T(rawValue: 1 << 40) // Карта
    static let goIntoUnknownRooms = T(rawValue: 1 << 41)

    var mudlogVerbosity: MudlogVerbosity {
        get {
            var rawValue: UInt8 = 0
            if contains(.logLevelBit1) {
                rawValue += 1
            }
            if contains(.logLevelBit2) {
                rawValue += 2
            }
            guard let result = MudlogVerbosity(rawValue: rawValue) else {
                assertionFailure()
                return .complete
            }
            return result
        }
        set {
            switch newValue {
            case .off:
                remove(.logLevelBit1)
                remove(.logLevelBit2)
            case .brief:
                insert(.logLevelBit1)
                remove(.logLevelBit2)
            case .normal:
                remove(.logLevelBit1)
                insert(.logLevelBit2)
            case .complete:
                insert(.logLevelBit1)
                insert(.logLevelBit2)
            }
        }
    }
    
    static var defaultFlags: PlayerPreferenceFlags {
        return [
            .displayHitPointsInPrompt,
            .displayXpInPrompt,
            .displayMovementInPrompt,
            .displayCoinsInPrompt,
            .dispmem,
            /* .displag, */
            .autoexit,
            .rememorize,
            .stackItems,
            .reply,
            .rentBank,
            .quantity,
            .map]
    }
}
