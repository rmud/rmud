import Foundation

fileprivate let commandInfo: [Command] = [
    
    // Move directions
    
    Command(["север", "north", "\u{1b}[A"], subcommand: .north, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["восток", "east", "\u{1b}[C"], subcommand: .east, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["юг", "south", "\u{1b}[B"], subcommand: .south, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["запад", "west", "\u{1b}[D"], subcommand: .west, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["подняться", "вверх", "up"], subcommand: .up, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),
    Command(["опуститься", "вниз", "down"], subcommand: .down, Creature.doMove,
            flags: [.highPriority, .noFight, .directionCommand]),

    // Movement
    
    Command(["смотреть", "look"], Creature.doLook,
            flags: [.highPriority], minPosition: .resting,
            arg1: [.creature, .item, .word], cases1: [.accusative], where1: [.equipment, .inventory, .room], extra1: .optional),
    Command(["карта", "map"], Creature.doMap,
            flags: [.highPriority], minPosition: .resting,
            arg1: .word, extra1: [/* .allowFillWords,*/ .optional]),
    Command(["оглядеться", "scan", "выходы"], Creature.doScan,
            flags: [.highPriority], minPosition: .resting),

    Command(["встать", "stand"], Creature.doStand,
            flags: [.highPriority], minPosition: .resting),

    Command(["спать", "sleep"], Creature.doSleep,
            flags: [.noFight, .noMount], minPosition: .resting),
    Command(["проснуться", "wake"], Creature.doWake,
            minPosition: .sleeping),

    Command(["инвентарь", "вещи", "inventory"], Creature.doInventory,
            flags: [.informational, .highPriority], minPosition: .sleeping),

    Command(["бросить", "drop"], Creature.doDrop,
            minPosition: .resting,
            arg1: .item, cases1: .accusative, where1: .inventory, extra1: [.oneOrMore, .optional]),

    // Shopsables, inns, bank and post-offices
    
    Command(["список", "list", "меню", "menu"], subcommand: .shopList, Creature.doService,
            flags: [.highPriority, .noFight],
            arg1: .word, extra1: .optional),
    
    // Information
        
    Command(["справка", "помощь", "help", "?"], Creature.doHelp,
            flags: .informational, minPosition: .sleeping),
    Command(["кто", "who"], Creature.doWho,
        flags: .informational, minPosition: .sleeping),
    Command(["счет", "score", "очки"], Creature.doScore,
        flags: .informational, minPosition: .sleeping,
        arg1: .word, extra1: [/*.allowFillWords,*/ .optional]),
    
    // Other
    
    Command(["режим", "option"], Creature.doOption,
            flags: .informational, minPosition: .sleeping,
            arg1: .word, extra1: .optional,
            arg2: .restOfString, extra2: .optional),

    Command(["область", "area"], Creature.doArea,
            flags: .informational, minPosition: .dead, minLevel: Level.greaterGod,
            arg1: .word, extra1: [.optional /*, .allowFillWords*/],
            arg2: [.restOfString], extra2: .optional),

    Command(["конец", "quit"], Creature.doQuit,
            flags: [.informational, .noFight], minPosition: .sleeping),
    Command(["конец!", "quit!"], subcommand: .quit, Creature.doQuit,
            flags: [.informational, .noFight], minPosition: .sleeping),

    // 31+
    
    Command(["идти", "goto"], Creature.doGoto,
            flags: .informational, minPosition: .dead, minLevel: Level.hero,
            arg1: .word, extra1: [/*.allowFillWords*/]),
        
    // 32+
        
    Command(["показать", "show"], Creature.doShow,
            flags: .informational, minPosition: .dead, minLevel: Level.lesserGod,
            arg1: .word, extra1: .optional,
            arg2: .restOfString, extra2: .optional
    ),
    
    Command(["создать", "load"], Creature.doLoad,
            flags: .informational, minPosition: .dead, minLevel: Level.lesserGod,
            arg1: .word, extra1: .optional,
            arg2: .word, extra2: .optional),

    Command(["установить", "set"], Creature.doSet,
            flags: .informational, minPosition: .dead, minLevel: Level.middleGod,
            arg1: .word, extra1: .optional,
            arg2: .word, extra2: .optional
    ),
        
    // 34+
    Command(["перечитать", "reload"], Creature.doReload,
            flags: .informational, minPosition: .dead, minLevel: Level.greaterGod,
            arg1: .word, extra1: .optional),
]

class CommandInterpreter {
    struct CommandAbbreviation {
        let command: String
        let abbreviation: String
    }

    static let sharedInstance = CommandInterpreter()

    var commandAbbreviations: [CommandAbbreviation] = []

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
            commandAbbreviations.append(commandAbbreviation)
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