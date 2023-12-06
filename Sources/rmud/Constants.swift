import Foundation

// Contains internal game constants
// For user-configurable settings, see Settings.swift

// TODO: put into namespace?

let optUsec = 100000     // 10 passes per second
let passesPerSec = 1000000 / optUsec

let pulseViolence = 3 * passesPerSec
let pulseMobile = pulseViolence
let pulseMobileOffset = pulseViolence / 2
let pulseTick =  60 * passesPerSec

let playerNameAllowedLettersLowercased = CharacterSet(charactersIn: "абвгдеёжзийклмнопрстуфхцчшщъыьэюя")
let playerMaxNameLength = 20 // Player's name length
let playerMaxPasswordLength = 255 // Player's password length


// Pager
let defaultPageWidth: Int16 = 76
let defaultPageLength: Int16 = 23

let defaultMaxIdle = 30
let maxIdleTimeAllowedInterval = 10...30

let shopMaximumItemCountOfSameTypeBeforeSellout = 5

let vnumMortalStartRoom = 2000
// TODO: move to area files
let vnumSolaceInn  = 2000
let vnumBaliforInn = 1069
let vnumKalamanInn = 1414
let vnumHyloInn    = 14062
let vnumHavenInn   = 26573

// Shops
let shopSellItemCountLimit = 100

// Item vnums
let vnumSpellDelayedBlastFireball = 13

let playerStartAgeYears: UInt64 = 16

// Game time
let secondsPerGameHour: UInt64 = 60
let hoursPerGameDay: UInt64 = 24
let secondsPerGameDay: UInt64 = hoursPerGameDay * secondsPerGameHour
let daysPerGameMonth: UInt64 = 30
let secondsPerGameMonth: UInt64 = daysPerGameMonth * secondsPerGameDay
let monthsPerGameYear: UInt64 = 12
let secondsPerGameYear: UInt64 = monthsPerGameYear * secondsPerGameMonth

// Real time
let secondsPerRealMinute: UInt64 = 60
let secondsPerRealHour: UInt64 = 60 * secondsPerRealMinute
let secondsPerRealDay: UInt64 = 24 * secondsPerRealHour
let secondsPerRealYear: UInt64 = 365 * secondsPerRealDay

let areaFileExtensions: [String] = ["area", "are", "arx"]
let worldFileExtensions: [String] = ["smud", "rooms", "mobiles", "items", "wlx", "obx", "mox"]

let defaultMapWidth: UInt8 = 5
let defaultMapHeight: UInt8 = 5
let validMapSizeRange: ClosedRange<UInt8> = 1...9

let selectCharset = """
    Please choose a MUD client:
      1: Any UTF-8 client
      2: ZMUD 3.0
      3: JMC
      4: ZMUD 7.0+

    Alternatively, choose an encoding:
      w: CP-1251 (WINDOWS)
      u: UTF-8 (Mac OS, Linux)
      k: KOI8-R
      d: CP-866 (DOS)
    """

let playerNameRules = """
    Придумайте имя Вашего персонажа. Основные требования:
    - имя должно соответствовать стилю жанра фэнтэзи и мира Копья;
    - имя не должно принадлежать герою или богу популярного произведения любого
      жанра;
    - имя не должно быть именем героя или бога в реальной мифологии или религии;
    - имя не должно состоять из двух или более слов;
    - имя не должно быть названием профессии, именем животного или монстра;
    - имя не должно быть транскрипцией распространенного английского слова.
    Персонажи с именами, не соответствующими правилам выбора имен,
    могут быть заблокированы до исправления имени.
    """

let playerLoadRooms = """
    Города, в которых Ваш персонаж может начать игру:
    1. Утеха
    2. Балифор
    3. Гавань
    4. Каламан
    5. Хилло
    Новичкам настоятельно рекомендуется выбирать Утеху.
    """

let accountMenu = """
    1) Выбрать персонажа.
    2) Изменить пароль учетной записи.
    3) Удалить учетную запись.
    0) Выйти из игры.
    """

let creatureMenu = """
    1) Войти в игру.
    2) Выбрать другого персонажа.
    3) Ввести описание персонажа.
    4) Получить тренировочную экипировку.
    5) Удалить персонажа.
    0) Назад в меню учетной записи.
    """

let fillWordsBeforeFirstArgLowercased = Set<String>([
    "в", "in"
])

let fillWordsLowercased = Set<String>([
    "в", "из", "от", "с", "о", "со", "на", "за", "к", "для",
    "from", "with", "in", "on", "at", "to", "for", "a", "an", "the"
])

let maximumMortalLevel: UInt8 = 30

// Two very basic tables used in many functions
private let tableA: [Int] = [ // 0 - 36
    -50, // 0
    -40,-35,-30,-25,-20,-16,-12, -9, -6, -4, // 10
    -2, -1,  0,  1,  2,  4,  6,  8, 10, 13, // 20
    16, 19, 22, 26, 30, 34, 38, 42, 46, 50, // 30
    55, 60, 65, 70, 75, 80
]

private let tableB: [Int] = [ // 0 - 30
    0,
    4,  8, 12, 16, 20,
    25, 30, 35, 40, 44,
    48, 52, 56, 60, 64,
    69, 71, 74, 77, 80,
    82, 84, 86, 88, 90,
    92, 94, 96, 98, 100
]

func tableB<T: NumericType, I: BinaryInteger>(_ index: I) -> T {
    // All values in tableB can fit into any NumericType, so it's safe not to check
    // if the cast was successful.
    if index < 0 {
        return T(tableB[0])
    } else if index >= tableB.count {
        return T(tableB[tableB.count - 1])
    }
    return T(tableB[Int(index)])
}
