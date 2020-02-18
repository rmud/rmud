import Foundation

extension Creature {
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
        commandInterpreter.enumerateCommands(minimumLevel: level, commandPrefix: commandPrefix, fullDirections: fullDirections) { command, stop in
            
            found = true
            stop = true

            wasDirectionCommand = command.group == .movement && command.flags.contains(.directionCommand)

            var context = CommandContext(command: command, scanner: scanner)
            context.subcommand = command.subcommand
            guard fetchArgument(from: scanner,
                                what: command.arg1What,
                                where: command.arg1Where,
                                cases: command.arg1Cases,
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
                                intoCreatures: &context.creatures2,
                                intoItems: &context.items2,
                                intoArgument: &context.argument2) else {
                nonOptionalArgumentMissing(command.arg2What)
                return
            }
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
    
    private func fetchArgument(from scanner: Scanner,
                               what: CommandArgumentFlags.What,
                               where whereAt: CommandArgumentFlags.Where,
                               cases: GrammaticalCases,
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
            return true // all args are optional now // extra.contains(.optional)
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

        if !what.contains(.many) {
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
                guard /* extra.contains(.notOnlyVisible) || */ canSee(item) else { continue }
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
                guard /* extra.contains(.notOnlyVisible) || */ canSee(creature) else { continue }

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
            return true
        }

        return true
    }
}
