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

fileprivate func enumerateCommands(minimumLevel: UInt8, commandPrefix: String, fullDirections: Bool, handler: (_ command: Command, _ stop: inout Bool) -> ()) {
    
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

extension Creature {
    func interpretCommand(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespaces)
        
        // Just drop to next line for hitting CR
        guard !trimmed.isEmpty else { return }

        let scanner = Scanner(string: trimmed)
        
        guard let commandPrefix = scanner.scanUpToCharacters(from: .whitespaces) else {
            return
        }
        
        let nonOptionalArgumentMissing: (_ what: CommandArgumentFlags.What)->() = { what in
            // TODO: multiple items/creatures?
            if what.contains(anyOf: [.word, .restOfString]) {
                self.send("Пожалуйста, укажите аргумент.")
            } else if what.contains(.creature) && what.contains(.item) {
                self.send("Пожалуйста, укажите персонажа или предмет.")
            } else if what.contains(.creature) {
                self.send("Пожалуйста, укажите персонажа.")
            } else if what.contains(.item) {
                self.send("Пожалуйста, укажите предмет.")
            } else {
                self.send("Пожалуйста, укажите аргумент.")
            }
        }
        
        var found = false
        let fullDirections = preferenceFlags?.contains(.fullDirections) ?? false
        enumerateCommands(minimumLevel: level, commandPrefix: commandPrefix, fullDirections: fullDirections) { command, stop in
            
            found = true
            stop = true
            
            var context = CommandContext(command: command, scanner: scanner)
            context.subcommand = command.subcommand
            guard fetchArgument(from: scanner,
                                what: command.arg1What,
                                where: command.arg1Where,
                                cases: command.arg1Cases,
                                extra: command.arg1Extra,
                                intoCreatures: &context.creatures1,
                                intoItems: &context.items1,
                                intoArgument: &context.argument1) else {
                nonOptionalArgumentMissing(command.arg1What)
                return
                                    
            }
            guard fetchArgument(from: scanner,
                                what: command.arg2What,
                                where: command.arg2Where,
                                cases: command.arg2Cases,
                                extra: command.arg2Extra,
                                intoCreatures: &context.creatures2,
                                intoItems: &context.items2,
                                intoArgument: &context.argument2) else {
                nonOptionalArgumentMissing(command.arg2What)
                return
            }
            command.handler(self)(context)
        }
        
        if !found {
            send("Хмм?")
        }
    }
    
    private func fetchArgument(from scanner: Scanner,
                               what: CommandArgumentFlags.What,
                               where whereAt: CommandArgumentFlags.Where,
                               cases: GrammaticalCases,
                               extra: CommandArgumentFlags.Extra,
                               intoCreatures: inout [Creature],
                               intoItems: inout [Item],
                               intoArgument: inout String) -> Bool {
        
        // Exit early if no argument was requested
        guard what.contains(anyOf: [.creature, .item, .word, .restOfString]) else {
            return true
        }

        let extractIndexAndAmount: (_ word: String) -> (name: String?, startIndex: Int, amount: Int) = { word in
            if word.isEqual(toOneOf: ["все", "всем", "all"], caseInsensitive: true) {
                return (nil, 1, Int.max)
            }
            
            let scanner = Scanner(string: word)
            var startIndex = 1
            var amount = 1
            while true {
                let startLocation = scanner.scanLocation
                if scanner.skipString("все.") || scanner.skipString("all.") {
                    amount = Int.max
                } else if let number = scanner.scanInteger() {
                    if scanner.skipString("*") {
                        amount = number
                    } else if scanner.skipString(".") {
                        startIndex = number
                    } else {
                        // Syntax error, just treat as part of name
                        scanner.scanLocation = startLocation
                        break
                    }
                } else {
                    // The rest is name
                    break
                }
            }
            return (scanner.textToParse.trimmingCharacters(in: .whitespaces), max(startIndex, 1), max(amount, 1))
        }
        
        // Try to process argument in following order:
        // - as me
        // - items worn / equipped
        // - items in inventory
        // - creatures in room
        // - items in room
        // - creatures in world
        // - items in world
        // - as word
        // - as rest of string
        
        // Creatures, items and words are described by single word, so try to read one from input:
        let originalScanLocation = scanner.scanLocation // in case we need to undo word read later
        guard let word = scanner.scanUpToCharacters(from: .whitespaces) else {
            return extra.contains(.optional)
        }
        
        // - as me
        // FIXME: move all reserved keywords to a class, assign variables to them and don't reference them as text,
        // exclude them from valid names
        if what.contains(.creature) && whereAt.contains(anyOf: [.room, .world]) &&
                word.isEqual(toOneOf: ["себя", "себе", "собой", "я", "меня", "мне", "мной",
                                       "i", "self", "me"], caseInsensitive: true) {
            intoCreatures.append(self)
            return true
        }
        
        var targetName: String? = nil
        var targetStartIndex = 1
        var targetAmount = 1
        if what.contains(anyOf: [.creature, .item]) {
            (targetName, targetStartIndex, targetAmount) = extractIndexAndAmount(word)
        }
        //print("fetchArgument: name=\(targetName ?? "nil"), index=\(targetIndex), amount=\(amount)")

        if !extra.contains(.oneOrMore) {
            targetAmount = 1
        }
        
        var currentIndex = 1
        var objectsAdded = 0

        // - items worn / equipped
        // TODO
        
        // - items in inventory
        if what.contains(.item) && whereAt.contains(anyOf: [.inventory, .world]) {
            for item in carrying {
                guard targetName == nil || item.isAbbrevOfNameOrSynonym(targetName!, cases: cases) else { continue }
                guard extra.contains(.notOnlyVisible) || canSee(item) else { continue }
                defer { currentIndex += 1 }
                guard currentIndex >= targetStartIndex else { continue }
                
                objectsAdded += 1
                intoItems.append(item)

                guard objectsAdded < targetAmount else { return true }
            }
        }

        // - creatures in room
        if what.contains(.creature), whereAt.contains(anyOf: [.room, .world]), let roomCreatures = inRoom?.creatures {
            for creature in roomCreatures {
                
                guard creature.isPlayer || !what.contains(.noMobile) else { continue }
                guard targetName == nil || creature.isAbbrevOfNameOrSynonym(targetName!, cases: cases) else { continue }
                guard extra.contains(.notOnlyVisible) || canSee(creature) else { continue }

                defer { currentIndex += 1 }
                guard currentIndex >= targetStartIndex else { continue }
                
                objectsAdded += 1
                intoCreatures.append(creature)
                
                guard objectsAdded < targetAmount else { return true }
            }
        }

        // - items in room
        // TODO

        // - creatures in world
        // TODO

        // - items in world
        // TODO

        // - as word
        if what.contains(.word) {
            intoArgument = word
            return true
        }

        // - as rest of string
        if what.contains(.restOfString) {
            scanner.scanLocation = originalScanLocation // undo word read
            intoArgument = scanner.textToParse.trimmingCharacters(in: .whitespaces)
            if intoArgument.isEmpty {
                return extra.contains(.optional)
            }
            return true
        }
        return true
    }
}
