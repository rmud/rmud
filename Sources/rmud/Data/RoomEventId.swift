import Foundation

enum RoomEventId: UInt16 {
    case invalid      = 0
    case openDoor     = 1 // disabled
    case closeDoor    = 2 // disabled
    case failPick     = 3 // disabled
    case okPick       = 4 // disabled
    case get          = 5
    case hide         = 6
    case rest         = 7
    case sit          = 8
    case sleep        = 9
    case stand        = 10
    case wake         = 11
    case noFlee       = 12
    case maneuvre     = 13
    case maneuvreFail = 14
    
    static let aliases = ["кперехват.событие"]

    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            // define MOVR_ROOM_OPNDOOR     1 // disabled
            // define MOVR_ROOM_CLSDOOR     2 // disabled
            // define MOVR_ROOM_FAILPICK    3 // disabled
            // define MOVR_ROOM_OKPICK      4 // disabled
            5:   "взять",           // Комната: ВЗЯТЬ
            6:   "прятаться",       // Комната: ПРЯТАТЬСЯ
            7:   "отдохнуть",       // Комната: ОТДОХНУТЬ
            8:   "сидеть",          // Комната: СИДЕТЬ
            9:   "спать",           // Комната: СПАТЬ
            // FIXME: разделить их?
            //10:  "встать",          // Комната: ВСТАТЬ из положения СИДЕТЬ
            //11:  "овстать",         // Комната: ВСТАТЬ из положения ОТДЫХАТЬ
            10:  "встать",          // Комната: ВСТАТЬ
            11:  "проснуться",      // Комната: ПРОСНУТЬСЯ
            12:  "несбежать",       // Комната: нельзя сбежать и трудно маневрировать
            13:  "маневр",         // Комната: маневрировать (отрицательнное - блокирует)
            14:  "маневр_неудача",  // Комната: маневр не получился
        ])
    }
}
