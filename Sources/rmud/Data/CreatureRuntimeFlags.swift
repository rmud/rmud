import Foundation

// Runtime flags: used by char_data.flags
struct CreatureRuntimeFlags: OptionSet {
    typealias T = CreatureRuntimeFlags
    let rawValue: UInt32
    
    static let follow        = T(rawValue: 1 << 0)  // Used in perform_move
    static let order         = T(rawValue: 1 << 1)  // Used by do_order
    static let invis         = T(rawValue: 1 << 2)  // Used by perform_immortal_invis
    static let force         = T(rawValue: 1 << 3)  // Used by do_force
    static let magic         = T(rawValue: 1 << 4)  // Used by call_magic
    static let wasLag        = T(rawValue: 1 << 5)  // Used for prompt redraw after lag ends
    static let dodge         = T(rawValue: 1 << 6)  // Used for thiev's double-dodge
    static let affInvis      = T(rawValue: 1 << 7)  // Used by affbit_update
    static let mistarget     = T(rawValue: 1 << 8)  // Used in fight, perform_dodge and damage_prepare
    static let dgForce       = T(rawValue: 1 << 9)  // Used by (m/o/w)
    static let noSetFight    = T(rawValue: 1 << 10) // Для самовзрыва "огн.крист." - не начинать бой со своими
    static let delayFlee     = T(rawValue: 1 << 11) // Задержка бегства (когда после damage() ещё что-то происходит
    static let falling       = T(rawValue: 1 << 12) // Персонаж вошел в комнату ВОЗДУХ без полёта и должен упасть
    static let suppressPrompt = T(rawValue: 1 << 13) // Suppress prompt on state transitions

    static let hiding        = T(rawValue: 1 << 14) // Персонаж прячется
    static let failedHide    = T(rawValue: 1 << 15) // Персонаж провалил попытку спрятаться
    static let sneaking      = T(rawValue: 1 << 16) // Персонаж крадется
    static let orienting     = T(rawValue: 1 << 17)
    static let doublecrossing = T(rawValue: 1 << 18)
    static let listening     = T(rawValue: 1 << 19)
}
