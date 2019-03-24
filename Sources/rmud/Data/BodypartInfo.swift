import Foundation

// Описывает свойства позиции для надевания вещей
struct BodypartInfo {
    /* Биты для bodyparts_data::options */
    struct Options: OptionSet {
        typealias T = Options
        
        let rawValue: UInt8
        //static let armor = T(rawValue: 1 << 0) // Место для ношения доспехов
        static let mageNoMetal = T(rawValue: 1 << 0) // Маги не колдуют в металлических доспехах и прочих вещах из простых металлов.
        static let rogueNoMetal = T(rawValue: 1 << 1) // Металл мешает вору
        // свойства позиций:
        // - маг не колдует в металле
        // - маг не колдует в недрагоценном металле
        // - металл мешает вору
        // - в руках
        // - AC factor
    }

    var name: String
    var itemWearFlags: ItemWearFlags
    var armor: UInt8
    var fragChance: UInt8 // зависит от общей площади и расположения
    var options: Options // константы WOPT_*
    
    init(name: String, itemWearFlags: ItemWearFlags, armor: UInt8, fragChance: UInt8, options: Options) {
        self.name = name
        self.itemWearFlags = itemWearFlags
        self.armor = armor
        self.fragChance = fragChance
        self.options = options
    }

    init(_ name: String, _ itemWearFlags: ItemWearFlags, _ armor: UInt8, _ fragChance: UInt8, _ options: Options) {
        self.init(name: name, itemWearFlags: itemWearFlags, armor: armor, fragChance: fragChance, options: options)
    }
}
