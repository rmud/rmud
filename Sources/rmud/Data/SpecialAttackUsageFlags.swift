import Foundation

// Spec attacks usage bits
struct SpecialAttackUsageFlags: OptionSet {
    typealias T = SpecialAttackUsageFlags
    
    let rawValue: UInt8
    
    static let attack1 = T(rawValue: 1 << 0) // активируется при успешной основной атаке
    static let attack2 = T(rawValue: 1 << 1) // активируется при успешной дополнительной атаке
    static let start   = T(rawValue: 1 << 2) // в начале боя
    static let death   = T(rawValue: 1 << 3) // в момент смерти моба
    static let once    = T(rawValue: 1 << 4) // не более раза в отдельном бою
    static let rare    = T(rawValue: 1 << 5) // вдвое реже, чем SELDOM, а вместе с ним - и ещё реже
    static let seldom  = T(rawValue: 1 << 6) // используется реже (пониженный шанс, что будет выбрана)
    // может комбинироваться с once
    static let always  = T(rawValue: 1 << 7) // используется даже в лаге
    // (но всё равно не используется в отключке или в skip_round)
    
    static let aliases = ["спец.применение"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1: "атака1",     // Когда основная атака попадает в цель
            2: "атака2",     // Когда дополнительная атака попадает в цель
            3: "начало",     // В начале каждого боя
            4: "смерть",     // В момент смерти монстра
            5: "однократно", // Один раз за бой (не более, но может и ни разу)
            6: "оченьредко", // Ещё реже, чем РЕДКО, в сочетании с РЕДКО - и ещё более редко
            7: "редко",      // Реже, чем другие спец-атаки
            8: "всегда",     // -Используется всегда, не зависимо от состояния
        ])
    }
    
}
