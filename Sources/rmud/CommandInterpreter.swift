import Foundation

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
    Command(["следовать", "follow"], group: .movement, Creature.notImplemented),

    // Communication
    Command(["сказать", "tell"], group: .communication, Creature.notImplemented),
    Command(["ответить", "reply"], group: .communication, Creature.notImplemented),
    Command(["произнести", "say"], group: .communication, Creature.notImplemented),
    Command(["крикнуть", "shout"], group: .communication, Creature.notImplemented),
    Command(["приказать", "order"], group: .communication, Creature.notImplemented),
    Command(["группа", "group"], group: .communication, Creature.notImplemented),
    Command(["гговорить", "gtell"], group: .communication, Creature.notImplemented),
    Command(["*"], group: .communication, Creature.notImplemented),
    Command(["эмоции", "emote"], group: .communication, Creature.notImplemented),

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
    Command(["взглянуть", "glance"], group: .information, Creature.notImplemented),
    Command(["наблюдать", "watch"], group: .information, Creature.notImplemented),
    Command(["оглядеться", "scan", "выходы"], group: .information, Creature.doScan,
            minPosition: .resting),
    Command(["кто", "who"], group: .information, Creature.doWho,
        flags: .informational, minPosition: .sleeping),
    Command(["счет", "score"], group: .information, Creature.doScore,
        flags: .informational, minPosition: .sleeping,
        arg1: .word, extra1: [/*.allowFillWords,*/ .optional]),
    Command(["титул", "title"], group: .information, Creature.notImplemented),
    Command(["время", "time"], group: .information, Creature.notImplemented),
    Command(["луны", "moons"], group: .information, Creature.notImplemented),
    Command(["режим", "option"], group: .information, Creature.doOption,
            flags: .informational, minPosition: .sleeping,
            arg1: .word, extra1: .optional,
            arg2: .restOfString, extra2: .optional),

    // Position
    Command(["встать", "stand"], group: .position, Creature.doStand,
            minPosition: .resting),
    Command(["отдохнуть", "rest"], group: .position, Creature.notImplemented),
    Command(["спать", "sleep"], group: .position, Creature.doSleep,
            flags: [.noFight, .noMount], minPosition: .resting),
    Command(["проснуться", "wake"], group: .position, Creature.doWake,
            minPosition: .sleeping),
    Command(["будить", "awaken"], group: .position, Creature.notImplemented),

    // Items
    Command(["вещи", "inventory", "инвентарь"], group: .items, Creature.doInventory,
            flags: [.informational], minPosition: .sleeping),
    Command(["экипировка", "equipment"], group: .items, Creature.notImplemented),
    Command(["взять", "get"], group: .items, Creature.notImplemented),
    Command(["положить", "put"], group: .items, Creature.notImplemented),
    Command(["надеть", "wear"], group: .items, Creature.notImplemented),
    Command(["снять", "remove"], group: .items, Creature.notImplemented),
    Command(["дать", "give"], group: .items, Creature.notImplemented),
    Command(["делить", "split"], group: .items, Creature.notImplemented),
    Command(["бросить", "drop"], group: .items, Creature.doDrop,
            minPosition: .resting,
            arg1: .item, cases1: .accusative, where1: .inventory, extra1: [.oneOrMore, .optional]),
    Command(["вооружиться", "wield"], group: .items, Creature.notImplemented),
    Command(["держать", "hold"], group: .items, Creature.notImplemented),
    Command(["убрать", "remove"], group: .items, Creature.notImplemented),

    // DoorsAndContainers
    Command(["закрыть", "close"], group: .doorsAndContainers, Creature.notImplemented),
    Command(["открыть", "open"], group: .doorsAndContainers, Creature.notImplemented),
    Command(["запереть", "lock"], group: .doorsAndContainers, Creature.notImplemented),
    Command(["отпереть", "unlock"], group: .doorsAndContainers, Creature.notImplemented),

    // Food
    Command(["наполнить", "fill"], group: .food, Creature.notImplemented),
    Command(["опорожнить", "empty"], group: .food, Creature.notImplemented),
    Command(["перелить", "pour"], group: .food, Creature.notImplemented),
    Command(["пить", "drink"], group: .food, Creature.notImplemented),
    Command(["пригубить", "sip"], group: .food, Creature.notImplemented),
    Command(["есть", "eat"], group: .food, Creature.notImplemented),
    Command(["пробовать", "taste"], group: .food, Creature.notImplemented),

    // Mounts
    Command(["вскочить", "mount"], group: .mounts, Creature.notImplemented),
    Command(["соскочить", "unmount"], group: .mounts, Creature.notImplemented),
    Command(["привязать", "fill"], group: .mounts, Creature.notImplemented),
    Command(["отвязать", "fill"], group: .mounts, Creature.notImplemented),

    // MagicItems
    Command(["осушить", "quaff"], group: .mounts, Creature.notImplemented),
    Command(["зачитать", "recite"], group: .mounts, Creature.notImplemented),
    Command(["взмахнуть", "wave"], group: .mounts, Creature.notImplemented),
    Command(["указать", "point"], group: .mounts, Creature.notImplemented),

    // SkillsAndSpells
    Command(["умения", "skills"], group: .skillsAndSpells, Creature.notImplemented),
    Command(["заклинания", "spells"], group: .skillsAndSpells, Creature.notImplemented),
    Command(["запомнить", "memorize"], group: .skillsAndSpells, Creature.notImplemented),
    Command(["забыть", "forget"], group: .skillsAndSpells, Creature.notImplemented),
    Command(["колдовать", "cast"], group: .skillsAndSpells, Creature.notImplemented),
    Command(["появиться", "appear"], group: .skillsAndSpells, Creature.notImplemented),

    // Combat
    Command(["сравнить", "consider"], group: .combat, Creature.notImplemented),
    Command(["убить", "kill"], group: .combat, Creature.notImplemented),
    Command(["бежать", "flee"], group: .combat, Creature.notImplemented),
    Command(["отступить", "retreat"], group: .combat, Creature.notImplemented),
    Command(["помочь", "assist"], group: .combat, Creature.notImplemented),

    // ShopsAndStables
    Command(["список", "list", "меню", "menu"], group: .shopsAndStables, subcommand: .shopList, Creature.doService,
            flags: [.noFight],
            arg1: .word, extra1: .optional),
    Command(["купить", "buy"], group: .shopsAndStables, Creature.notImplemented),
    Command(["продать", "sell"], group: .shopsAndStables, Creature.notImplemented),
    Command(["чинить", "repair"], group: .shopsAndStables, Creature.notImplemented),
    Command(["оценить", "evaluate"], group: .shopsAndStables, Creature.notImplemented),
    Command(["сдать", "stable"], group: .shopsAndStables, Creature.notImplemented),
    Command(["забрать", "redeem"], group: .shopsAndStables, Creature.notImplemented),

    // Banks
    Command(["баланс", "balance"], group: .banks, Creature.notImplemented),
    Command(["вложить", "deposit"], group: .banks, Creature.notImplemented),
    Command(["получить", "withdraw"], group: .banks, Creature.notImplemented),

    // Taverns
    Command(["стоимость", "offer"], group: .taverns, Creature.notImplemented),
    Command(["прописаться", "register"], group: .taverns, Creature.notImplemented),
    Command(["постой", "rent"], group: .taverns, Creature.notImplemented),
    Command(["конец", "quit"], group: .taverns, Creature.doQuit,
            flags: [.informational, .noFight], minPosition: .sleeping),
    Command(["конец!", "quit!"], group: .taverns, subcommand: .quit, Creature.doQuit,
            flags: [.informational, .noFight], minPosition: .sleeping),

    // Other
    Command(["правила", "rules"], group: .other, Creature.notImplemented),
    Command(["новости", "news"], group: .other, Creature.notImplemented),
    Command(["система", "system"], group: .other, Creature.notImplemented),
    Command(["благодарности", "credits"], group: .other, Creature.notImplemented),
    Command(["глюк", "bug"], group: .other, Creature.notImplemented),
    Command(["идея", "idea"], group: .other, Creature.notImplemented),
    Command(["опечатка", "typo"], group: .other, Creature.notImplemented),

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
    struct CommandAbbreviation {
        let command: String
        let abbreviation: String
    }

    static let sharedInstance = CommandInterpreter()

    typealias BestAbbreviations = [CommandAbbreviation]
    let commandGroups = OrderedDictionary<String, BestAbbreviations>()

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
            let commandAbbreviation = CommandAbbreviation(
                command: alias, abbreviation: abbreviation(for: alias))
            var bestAbbreviations = commandGroups[command.group.rawValue] ?? BestAbbreviations()
            bestAbbreviations.append(commandAbbreviation)
            commandGroups[command.group.rawValue] = bestAbbreviations
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