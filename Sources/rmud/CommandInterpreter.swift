import Foundation

fileprivate let notImplemented: Command.Handler? = nil

fileprivate let commandInfo: [Command] = [
    
    // Movement
    Command(["север", "north", "\u{1b}[A"], group: .movement, subcommand: .north, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["восток", "east", "\u{1b}[C"], group: .movement, subcommand: .east, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["юг", "south", "\u{1b}[B"], group: .movement, subcommand: .south, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["запад", "west", "\u{1b}[D"], group: .movement, subcommand: .west, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["подняться", "вверх", "up"], group: .movement, subcommand: .up, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["опуститься", "вниз", "down"], group: .movement, subcommand: .down, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["следовать", "follow"], group: .movement, notImplemented),

    // Communication
    Command(["сказать", "tell"], group: .communication, notImplemented),
    Command(["ответить", "reply"], group: .communication, notImplemented),
    Command(["произнести", "say"], group: .communication, notImplemented),
    Command(["крикнуть", "shout"], group: .communication, notImplemented),
    Command(["приказать", "order"], group: .communication, notImplemented),
    Command(["группа", "group"], group: .communication, notImplemented),
    Command(["гговорить", "gtell"], group: .communication, notImplemented),
    Command(["*"], group: .communication, notImplemented),
    Command(["эмоции", "emote"], group: .communication, notImplemented),

    // Information
    Command(["?"], group: .information, Creature.doHelp,
            flags: .informational, minPosition: .sleeping),
    Command(["справка", "помощь", "help"], group: .information, Creature.doHelp,
            flags: .informational, minPosition: .sleeping),
    Command(["карта", "map"], group: .information, Creature.doMap,
            minPosition: .resting,
            arg1: .word, extra1: [.optional]),
    Command(["смотреть", "look"], group: .information, Creature.doLook,
            minPosition: .resting,
            arg1: [.creature, .item, .word], cases1: [.accusative], where1: [.equipment, .inventory, .room], extra1: [.optional]),
    Command(["взглянуть", "glance"], group: .information, notImplemented),
    Command(["наблюдать", "watch"], group: .information, notImplemented),
    Command(["оглядеться", "scan", "выходы"], group: .information, Creature.doScan,
            minPosition: .resting),
    Command(["кто", "who"], group: .information, Creature.doWho,
        flags: .informational, minPosition: .sleeping),
    Command(["счет", "score"], group: .information, Creature.doScore,
        flags: .informational, minPosition: .sleeping,
        arg1: .word, extra1: [/*.allowFillWords,*/ .optional]),
    Command(["титул", "title"], group: .information, notImplemented),
    Command(["время", "time"], group: .information, notImplemented),
    Command(["луны", "moons"], group: .information, notImplemented),
    Command(["режим", "option"], group: .information, Creature.doOption,
            flags: .informational, minPosition: .sleeping,
            arg1: .word, extra1: .optional,
            arg2: .restOfString, extra2: .optional),

    // Position
    Command(["встать", "stand"], group: .position, Creature.doStand,
            minPosition: .resting),
    Command(["отдохнуть", "rest"], group: .position, notImplemented),
    Command(["спать", "sleep"], group: .position, Creature.doSleep,
            flags: [.noFight, .noMount], minPosition: .resting),
    Command(["проснуться", "wake"], group: .position, Creature.doWake,
            minPosition: .sleeping),
    Command(["будить", "awaken"], group: .position, notImplemented),

    // Items
    Command(["вещи", "inventory", "инвентарь"], group: .items, Creature.doInventory,
            flags: [.informational], minPosition: .sleeping),
    Command(["экипировка", "equipment"], group: .items, notImplemented),
    Command(["взять", "get"], group: .items, notImplemented),
    Command(["положить", "put"], group: .items, notImplemented),
    Command(["надеть", "wear"], group: .items, notImplemented),
    Command(["снять", "remove"], group: .items, notImplemented),
    Command(["дать", "give"], group: .items, notImplemented),
    Command(["делить", "split"], group: .items, notImplemented),
    Command(["бросить", "drop"], group: .items, Creature.doDrop,
            minPosition: .resting,
            arg1: .item, cases1: .accusative, where1: .inventory, extra1: [.oneOrMore, .optional]),
    Command(["вооружиться", "wield"], group: .items, notImplemented),
    Command(["держать", "hold"], group: .items, notImplemented),
    Command(["убрать", "remove"], group: .items, notImplemented),

    // DoorsAndContainers
    Command(["закрыть", "close"], group: .doorsAndContainers, notImplemented),
    Command(["открыть", "open"], group: .doorsAndContainers, notImplemented),
    Command(["запереть", "lock"], group: .doorsAndContainers, notImplemented),
    Command(["отпереть", "unlock"], group: .doorsAndContainers, notImplemented),

    // Food
    Command(["наполнить", "fill"], group: .food, notImplemented),
    Command(["опорожнить", "empty"], group: .food, notImplemented),
    Command(["перелить", "pour"], group: .food, notImplemented),
    Command(["пить", "drink"], group: .food, notImplemented),
    Command(["пригубить", "sip"], group: .food, notImplemented),
    Command(["есть", "eat"], group: .food, notImplemented),
    Command(["пробовать", "taste"], group: .food, notImplemented),

    // Mounts
    Command(["вскочить", "mount"], group: .mounts, notImplemented),
    Command(["соскочить", "unmount"], group: .mounts, notImplemented),
    Command(["привязать", "fill"], group: .mounts, notImplemented),
    Command(["отвязать", "fill"], group: .mounts, notImplemented),

    // MagicItems
    Command(["осушить", "quaff"], group: .mounts, notImplemented),
    Command(["зачитать", "recite"], group: .mounts, notImplemented),
    Command(["взмахнуть", "wave"], group: .mounts, notImplemented),
    Command(["указать", "point"], group: .mounts, notImplemented),

    // SkillsAndSpells
    Command(["умения", "skills"], group: .skillsAndSpells, notImplemented),
    Command(["заклинания", "spells"], group: .skillsAndSpells, notImplemented),
    Command(["запомнить", "memorize"], group: .skillsAndSpells, notImplemented),
    Command(["забыть", "forget"], group: .skillsAndSpells, notImplemented),
    Command(["колдовать", "cast"], group: .skillsAndSpells, notImplemented),
    Command(["появиться", "appear"], group: .skillsAndSpells, notImplemented),

    // Combat
    Command(["сравнить", "consider"], group: .combat, notImplemented),
    Command(["убить", "kill"], group: .combat, notImplemented),
    Command(["бежать", "flee"], group: .combat, notImplemented),
    Command(["отступить", "retreat"], group: .combat, notImplemented),
    Command(["помочь", "assist"], group: .combat, notImplemented),

    // ShopsAndStables
    Command(["список", "list", "меню", "menu"], group: .shopsAndStables, subcommand: .shopList, Creature.doService,
            flags: [.noFight],
            arg1: .word, extra1: .optional),
    Command(["купить", "buy"], group: .shopsAndStables, notImplemented),
    Command(["продать", "sell"], group: .shopsAndStables, notImplemented),
    Command(["чинить", "repair"], group: .shopsAndStables, notImplemented),
    Command(["оценить", "evaluate"], group: .shopsAndStables, notImplemented),
    Command(["сдать", "stable"], group: .shopsAndStables, notImplemented),
    Command(["забрать", "redeem"], group: .shopsAndStables, notImplemented),

    // Banks
    Command(["баланс", "balance"], group: .banks, notImplemented),
    Command(["вложить", "deposit"], group: .banks, notImplemented),
    Command(["получить", "withdraw"], group: .banks, notImplemented),

    // Taverns
    Command(["стоимость", "offer"], group: .taverns, notImplemented),
    Command(["прописаться", "register"], group: .taverns, notImplemented),
    Command(["постой", "rent"], group: .taverns, notImplemented),
    Command(["конец", "quit"], group: .taverns, Creature.doQuit,
            flags: [.informational, .noFight], minPosition: .sleeping),
    Command(["конец!", "quit!"], group: .taverns, subcommand: .quit, Creature.doQuit,
            flags: [.informational, .noFight, .hidden], minPosition: .sleeping),

    // Other
    Command(["правила", "rules"], group: .other, notImplemented),
    Command(["новости", "news"], group: .other, notImplemented),
    Command(["система", "system"], group: .other, notImplemented),
    Command(["благодарности", "credits"], group: .other, notImplemented),
    Command(["глюк", "bug"], group: .other, notImplemented),
    Command(["идея", "idea"], group: .other, notImplemented),
    Command(["опечатка", "typo"], group: .other, notImplemented),

    // Administrative

    // 31+
    Command(["идти", "goto"], group: .administrative, Creature.doGoto,
            flags: .informational, minPosition: .dead, minLevel: Level.hero,
            arg1: .word, extra1: []),
    
    // 32+
    Command(["показать", "show"], group: .administrative, Creature.doShow,
            flags: .informational, minPosition: .dead, minLevel: Level.lesserGod,
            arg1: .word, extra1: .optional,
            arg2: .restOfString, extra2: .optional
    ),
    Command(["создать", "load"], group: .administrative, Creature.doLoad,
            flags: .informational, minPosition: .dead, minLevel: Level.lesserGod,
            arg1: .word, extra1: .optional,
            arg2: .word, extra2: .optional),
    
    // 33+
    Command(["установить", "set"], group: .administrative, Creature.doSet,
            flags: .informational, minPosition: .dead, minLevel: Level.middleGod,
            arg1: .word, extra1: .optional,
            arg2: .word, extra2: .optional
    ),
    
    // 34+
    Command(["область", "area"], group: .administrative, Creature.doArea,
            flags: .informational, minPosition: .dead, minLevel: Level.greaterGod,
            arg1: .word, extra1: [.optional],
            arg2: [.restOfString], extra2: .optional),
    Command(["перечитать", "reload"], group: .administrative, Creature.doReload,
            flags: .informational, minPosition: .dead, minLevel: Level.greaterGod,
            arg1: .word, extra1: .optional),
]

class CommandInterpreter {
    struct CommandIndexEntry {
        let command: Command
        let commandName: String
        let abbreviation: String
    }

    static let sharedInstance = CommandInterpreter()

    typealias CommandIndexEntries = [CommandIndexEntry]
    let commandGroups = OrderedDictionary<String, CommandIndexEntries>()

    func enumerateCommands(minimumLevel: UInt8, commandPrefix: String, fullDirections: Bool, handler: (_ command: Command, _ stop: inout Bool) -> ()) {
        for priority in 0...1 {
            for command in commandInfo {
                switch priority {
                case 0: guard command.flags.contains([.highPriority]) else { continue }
                case 1: guard !command.flags.contains([.highPriority]) else { continue }
                default: break
                }
                
                guard minimumLevel >= command.minimumLevel else { continue }
                
                var foundAlias = false
                for alias in command.aliases {
                    if alias.hasPrefix(commandPrefix) {
                        foundAlias = true
                        break
                    }
                }
                guard foundAlias else { continue }
                
                var stop = false
                handler(command, &stop)
                guard !stop else { return }
            }
        }
    }

    func buildCommandIndex(minimumLevel: UInt8 = Level.implementor) {
        enumerateCommands(minimumLevel: minimumLevel, commandPrefix: "", fullDirections: true) { command, stop in
            guard let alias = command.aliases.first else { return }
            let commandIndexEntry = CommandIndexEntry(
                command: command,
                commandName: alias,
                abbreviation: abbreviation(for: alias))
            var entries = commandGroups[command.group.rawValue] ?? CommandIndexEntries()
            entries.append(commandIndexEntry)
            commandGroups[command.group.rawValue] = entries
        }
    }

    private func abbreviation(for commandAlias: String) -> String {
        for i in 1..<commandAlias.count {
            let subcommand = commandAlias.prefix(i)
            var foundSelf = false
            enumerateCommands(minimumLevel: Level.implementor, commandPrefix: String(subcommand), fullDirections: true) { command, stop in
                if let currentAlias = command.aliases.first, currentAlias == commandAlias {
                    foundSelf = true
                }
                stop = true
            }
            if foundSelf { return String(subcommand) }
        }
        return commandAlias
    }
}