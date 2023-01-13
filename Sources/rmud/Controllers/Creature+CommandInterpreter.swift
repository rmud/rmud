import Foundation

extension Creature {
    private struct FetchArgumentContext {
        var targetName: String? = nil
        var targetStartIndex = 1
        var targetAmount = 1
        
        var currentIndex = 1
        var objectsAdded = 0
        
        init(word: String, isCountable: Bool = true, isMany: Bool = false) {
            if isCountable {
                (targetName, targetStartIndex, targetAmount) = Self.extractIndexAndAmount(word)
            }
            
            if !isMany {
                targetAmount = 1
            }
        }
    
        static func extractIndexAndAmount(_ word: String) -> (name: String?, startIndex: Int, amount: Int) {
            if word.isEqual(toOneOf: ["все", "всем", "all"], caseInsensitive: true) {
                return (nil, 1, Int.max)
            }
            
            let scanner = Scanner(string: word)
            var startIndex = 1
            var amount = 1
            while true {
                let scannerStartIndex = scanner.string.startIndex
                if scanner.skipString("все.") || scanner.skipString("all.") {
                    amount = Int.max
                } else if let number = scanner.scanInteger() {
                    if scanner.skipString("*") {
                        amount = number
                    } else if scanner.skipString(".") {
                        startIndex = number
                    } else {
                        // Syntax error, just treat as part of name
                        scanner.currentIndex = scannerStartIndex
                        break
                    }
                } else {
                    // The rest is name
                    break
                }
            }
            return (scanner.textToParse.trimmingCharacters(in: .whitespaces), max(startIndex, 1), max(amount, 1))
        }
    }
    
    func interpretCommand(_ command: String) {
        // Cancel direction commands if any non-direction command is typed or even ENTER is pressed
        var wasDirectionCommand = false
        defer {
            if !wasDirectionCommand && !movementPath.isEmpty {
                movementPath.removeAll()
            }
        }
        
        let trimmed = command.trimmingCharacters(in: .whitespaces)
        
        // Just drop to next line for hitting CR
        guard !trimmed.isEmpty else { return }

        let scanner = Scanner(string: trimmed)
        
        guard let commandPrefix = scanner.scanUpToCharacters(from: .whitespaces) else {
            return
        }
        
        var found = false
        let fullDirections = preferenceFlags?.contains(.fullDirections) ?? false
        commandInterpreter.enumerateCommands(roles: player?.roles ?? [], commandPrefix: commandPrefix, fullDirections: fullDirections) { command, stop in
            
            found = true
            stop = true

            wasDirectionCommand = command.group == .movement && command.flags.contains(.directionCommand)

            var context = CommandContext(command: command, scanner: scanner)
            context.subcommand = command.subcommand
            fetchArgument(from: scanner,
                          what: command.arg1What,
                          where: command.arg1Where,
                          cases: command.arg1Cases,
                          intoCreatures: &context.creatures1,
                          intoItems: &context.items1,
                          intoString: &context.argument1)
            fetchArgument(from: scanner,
                          what: command.arg2What,
                          where: command.arg2Where,
                          cases: command.arg2Cases,
                          intoCreatures: &context.creatures2,
                          intoItems: &context.items2,
                          intoString: &context.argument2)
            if let handler = command.handler {
                handler(self)(context)
            } else {
                send("Эта команда всё ещё не реализована.")
            }
        }
        
        if !found {
            send("Хмм?")
        }
    }
    
    private func fetchSelf(word: String, into: inout [Creature]) -> Bool {
        if word.isEqual(toOneOf: ["себя", "себе", "собой", "я", "меня", "мне", "мной", "i", "self", "me"], caseInsensitive: true) {
            into.append(self)
            return true
        }
        return false
    }
    
    private func fetchItemsInInventory(context: inout FetchArgumentContext, into: inout [Item], cases: GrammaticalCases) -> Bool {
        for item in carrying {
            guard context.targetName == nil || item.isAbbrevOfNameOrSynonym(context.targetName!, cases: cases) else { continue }
            guard /* extra.contains(.notOnlyVisible) || */ canSee(item) else { continue }
            defer { context.currentIndex += 1 }
            guard context.currentIndex >= context.targetStartIndex else { continue }
            
            context.objectsAdded += 1
            into.append(item)
            
            guard context.objectsAdded < context.targetAmount else { return true }
        }
        return false
    }
    
    private func isMatchingCreature(creature: Creature, context: FetchArgumentContext, cases: GrammaticalCases, isPlayersOnly: Bool) -> Bool {
        guard creature.isPlayer || !isPlayersOnly else { return false }
        guard context.targetName == nil || creature.isAbbrevOfNameOrSynonym(context.targetName!, cases: cases) else { return false }
        guard /* extra.contains(.notOnlyVisible) || */ canSee(creature) else { return false }
        return true;
    }
    
    private func fetchCreaturesInRoom(context: inout FetchArgumentContext, into: inout [Creature], cases: GrammaticalCases, isPlayersOnly: Bool = false) -> Bool {
        guard let roomCreatures = inRoom?.creatures else { return false }
        
        for creature in roomCreatures {
            guard isMatchingCreature(creature: creature, context: context, cases: cases, isPlayersOnly: isPlayersOnly) else { continue }
            
            defer { context.currentIndex += 1 }
            guard context.currentIndex >= context.targetStartIndex else { continue }
            
            context.objectsAdded += 1
            into.append(creature)
            
            guard context.objectsAdded < context.targetAmount else { return true }
        }
        
        return false
    }
    
    private func fetchCreaturesInWorld(context: inout FetchArgumentContext, into: inout [Creature], cases: GrammaticalCases, skipInSameRoom: Bool, isPlayersOnly: Bool = false) -> Bool {
        for creature in db.creaturesInGame {
            guard isMatchingCreature(creature: creature, context: context, cases: cases, isPlayersOnly: isPlayersOnly) else { continue }
            if skipInSameRoom && inRoom == creature.inRoom { continue }
            
            defer { context.currentIndex += 1 }
            guard context.currentIndex >= context.targetStartIndex else { continue }
            
            context.objectsAdded += 1
            into.append(creature)
            
            guard context.objectsAdded < context.targetAmount else { return true }
        }
        
        return false
    }
    
    func fetchArgument(from scanner: Scanner,
                               what: CommandArgumentFlags.What,
                               where whereAt: CommandArgumentFlags.Where,
                               cases: GrammaticalCases,
                               intoCreatures: inout [Creature],
                               intoItems: inout [Item],
                               intoString: inout String) {
        // Exit early if no argument was requested
        guard what.contains(anyOf: [.creature, .item, .word, .restOfString]) else {
            return
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
        let originalScannerIndex = scanner.currentIndex // in case we need to undo word read later
        guard let word = scanner.scanUpToCharacters(from: .whitespaces) else {
            return
        }
        
        // - as me
        // FIXME: move all reserved keywords to a class, assign variables to them and don't reference them as text,
        // exclude them from valid names
        if what.contains(.creature) && whereAt.contains(anyOf: [.room, .world]) {
            if fetchSelf(word: word, into: &intoCreatures) {
                return
            }
        }
        
        let isCountable = what.contains(anyOf: [.creature, .item])
        let isMany = what.contains(.many)
        var context = FetchArgumentContext(word: word, isCountable: isCountable, isMany: isMany)

        // - items worn / equipped
        // TODO
        
        // - items in inventory
        if what.contains(.item) && whereAt.contains(anyOf: [.inventory, .world]) {
            if fetchItemsInInventory(context: &context, into: &intoItems, cases: cases) {
                return
            }
        }

        // - creatures in room
        if what.contains(.creature) && whereAt.contains(anyOf: [.room, .world]) {
            if fetchCreaturesInRoom(context: &context, into: &intoCreatures, cases: cases, isPlayersOnly: what.contains(.playersOnly)) {
                return
            }
        }

        // - items in room
        // TODO

        // - creatures in world
        if what.contains(.creature) && whereAt.contains(.world) {
            if fetchCreaturesInWorld(context: &context, into: &intoCreatures, cases: cases, skipInSameRoom: true, isPlayersOnly: what.contains(.playersOnly)) {
                return
            }
        }

        // - items in world
        // TODO

        // - as word
        if what.contains(.word) {
            intoString = word
            return
        }

        // - as rest of string
        if what.contains(.restOfString) {
            scanner.currentIndex = originalScannerIndex // undo word read
            intoString = scanner.textToParse.trimmingCharacters(in: .whitespaces)
            return
        }
    }
}
