import Foundation

extension Creature {
    enum TargetAmount {
        case count(Int)
        case infinite
    }
    
    struct FetchArgumentContext {
        var targetName = MultiwordArgument()
        var targetStartIndex = 1
        var targetAmount: TargetAmount = .count(1)
        
        var currentIndex = 1
        var objectsAdded = 0
        
        init(word: String, isCountable: Bool = true, isMany: Bool = false) {
            if isCountable {
                let targetNameString: String?
                (targetNameString, targetStartIndex, targetAmount) = Self.extractIndexAndAmount(word)
                targetName = MultiwordArgument(dotSeparatedWords: targetNameString)
            }
            
            if !isMany {
                targetAmount = .count(1)
            }
        }
    
        static func extractIndexAndAmount(_ word: String) -> (name: String?, startIndex: Int, amount: TargetAmount) {
            if word.isEqualCI(toAny: ["все", "всем", "all"]) {
                return (nil, 1, .infinite)
            }
            
            let scanner = Scanner(string: word)
            var startIndex = 1
            var amount: TargetAmount = .count(1)
            while true {
                let scannerStartIndex = scanner.string.startIndex
                if scanner.skipString("все.") || scanner.skipString("all.") {
                    amount = .infinite
                } else if let number = scanner.scanInteger() {
                    if scanner.skipString("*") {
                        amount = .count(number)
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
            if case .count(let value) = amount, value < 1 {
                amount = .count(1)
            }
            return (
                scanner.textToParse.trimmingCharacters(in: .whitespaces),
                max(startIndex, 1),
                amount
            )
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

            let gotArg1 = fetchArgument(from: scanner,
                          what: command.arg1What,
                          where: command.arg1Where,
                          cases: command.arg1Cases,
                          condition: { !isFillWordBeforeFirstArg($0) },
                          intoCreatures: &context.creatures1,
                          intoItems: &context.items1,
                          intoRoom: &context.room1,
                          intoString: &context.argument1)
            if gotArg1 {
                guard !command.arg1What.isGameObject || context.hasArgument1 else {
                    sendNothingFound(of: command.arg1What, where: command.arg1Where)
                    return
                }
                
                let gotArg2 = fetchArgument(from: scanner,
                              what: command.arg2What,
                              where: command.arg2Where,
                              cases: command.arg2Cases,
                              condition: { !isFillWord($0) },
                              intoCreatures: &context.creatures2,
                              intoItems: &context.items2,
                              intoRoom: &context.room2,
                              intoString: &context.argument2)
                if gotArg2 {
                    guard !command.arg2What.isGameObject || context.hasArgument2 else {
                        sendNothingFound(of: command.arg2What, where: command.arg2Where)
                        return
                    }
                }
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

    func fetchItemsInEquipment(context: inout FetchArgumentContext, into: inout [Item], cases: GrammaticalCases) -> Bool {
        let items: [Item] = EquipmentPosition.allCases.map { position in
            equipment[position]
        }.compactMap({ $0 })
        return fetchItems(context: &context, from: items, into: &into, cases: cases, condition: { _ in true })
    }
    
    func fetchItemsInInventory(context: inout FetchArgumentContext, into: inout [Item], cases: GrammaticalCases) -> Bool {
        return fetchItems(context: &context, from: carrying, into: &into, cases: cases, condition: { _ in true })
    }

    func fetchItemsInRoom(context: inout FetchArgumentContext, into: inout [Item], cases: GrammaticalCases) -> Bool {
        let items = inRoom?.items ?? []
        return fetchItems(context: &context, from: items, into: &into, cases: cases, condition: { _ in true })
    }
     
    func fetchItemsInArea(context: inout FetchArgumentContext, into: inout [Item], cases: GrammaticalCases) -> Bool {
        return fetchItems(
            context: &context,
            from: db.itemsInGame,
            into: &into,
            cases: cases,
            condition: { item in
                guard !isSameRoom(with: item) else { return false }
                guard isSameArea(with: item) else { return false }
                return true
            }
        )
    }

    func fetchItemsInWorld(context: inout FetchArgumentContext, into: inout [Item], cases: GrammaticalCases) -> Bool {
        return fetchItems(
            context: &context,
            from: db.itemsInGame,
            into: &into,
            cases: cases,
            condition: { item in
                guard !isSameRoom(with: item) else { return false }
                guard !isSameArea(with: item) else { return false }
                return true
            }
        )
    }

    func fetchCreaturesInRoom(context: inout FetchArgumentContext, into: inout [Creature], cases: GrammaticalCases, isPlayersOnly: Bool) -> Bool {
        let roomCreatures = inRoom?.creatures ?? []
        return fetchCreatures(
            context: &context,
            from: roomCreatures,
            into: &into,
            cases: cases,
            condition: { creature in
                guard isSameRoom(with: creature) else { return false }
                guard !isPlayersOnly || creature.isPlayer else { return false }
                return true
            }
        )
    }
    
    func fetchCreaturesInArea(context: inout FetchArgumentContext, into: inout [Creature], cases: GrammaticalCases, isPlayersOnly: Bool) -> Bool {
        return fetchCreatures(
            context: &context,
            from: db.creaturesInGame,
            into: &into,
            cases: cases,
            condition: { creature in
                guard !isSameRoom(with: creature) else { return false }
                guard isSameArea(with: creature) else { return false }
                guard !isPlayersOnly || creature.isPlayer else { return false }
                return true
            }
        )
    }

    func fetchCreaturesInWorld(context: inout FetchArgumentContext, into: inout [Creature], cases: GrammaticalCases, isPlayersOnly: Bool) -> Bool {
        return fetchCreatures(
            context: &context,
            from: db.creaturesInGame,
            into: &into,
            cases: cases,
            condition: { creature in
                guard !isSameRoom(with: creature) else { return false }
                guard !isSameArea(with: creature) else { return false }
                guard !isPlayersOnly || creature.isPlayer else { return false }
                return true
            }
        )
    }

    private func isMatchingItem(
        _ item: Item,
        context: FetchArgumentContext,
        cases: GrammaticalCases,
        condition: (_ item: Item) -> Bool
    ) -> Bool {
        guard condition(item) else { return false }
        guard context.targetName.isEmpty ||
                context.targetName.words.allSatisfy({ word in
                    isVnum(word, of: item) ||
                    item.isAbbrevOfNameOrSynonym(word, cases: cases)
                }) else {
                    return false
                }
        guard /* extra.contains(.notOnlyVisible) || */ canSee(item) else { return false }
        return true
    }

    private func fetchItems(context: inout FetchArgumentContext, from items: [Item], into: inout [Item], cases: GrammaticalCases, condition: (_ item: Item) -> Bool) -> Bool {
        for item in items {
            guard isMatchingItem(item, context: context, cases: cases, condition: condition) else { continue }

            defer { context.currentIndex += 1 }
            guard context.currentIndex >= context.targetStartIndex else { continue }
            
            context.objectsAdded += 1
            into.append(item)
            
            if case .count(let maxObjects) = context.targetAmount {
                guard context.objectsAdded < maxObjects else { return true }
            }
        }
        return false
    }
      
    private func fetchSelf(word: String, into: inout [Creature]) -> Bool {
        if word.isEqualCI(toAny: ["себя", "себе", "собой", "я", "меня", "мне", "мной", "i", "self", "me"]) {
            into.append(self)
            return true
        }
        return false
    }
  
    private func isMatchingCreature(
        _ creature: Creature,
        context: FetchArgumentContext,
        cases: GrammaticalCases,
        condition: (_ creature: Creature) -> Bool
    ) -> Bool {
        guard condition(creature) else { return false }
        guard context.targetName.isEmpty ||
                context.targetName.words.allSatisfy({ word in
                    isVnum(word, of: creature) ||
                    creature.isAbbrevOfNameOrSynonym(word, cases: cases)
                }) else {
                    return false
                }
        guard /* extra.contains(.notOnlyVisible) || */ canSee(creature) else { return false }
        return true;
    }
    
    private func fetchCreatures(
        context: inout FetchArgumentContext,
        from creatures: [Creature],
        into: inout [Creature],
        cases: GrammaticalCases,
        condition: (_ creature: Creature) -> Bool
    ) -> Bool {
        for creature in creatures {
            guard isMatchingCreature(creature, context: context, cases: cases, condition: condition) else { continue }

            defer { context.currentIndex += 1 }
            guard context.currentIndex >= context.targetStartIndex else { continue }
            
            context.objectsAdded += 1
            into.append(creature)

            if case .count(let maxObjects) = context.targetAmount {
                guard context.objectsAdded < maxObjects else { return true }
            }
        }
        
        return false
    }
    
    private func fetchRoom(context: inout FetchArgumentContext, into: inout Room?) -> Bool {
        guard isGodMode() else { return false }

        let argument = context.targetName.full
        
        var roomVnum: Int?
        if argument.allSatisfy({ $0.isNumber }) {
            roomVnum = Int(argument)
        } else if argument.starts(with: "к") || argument.starts(with: "К") {
            let num = argument.dropFirst()
            if num.allSatisfy({ $0.isNumber }) {
                roomVnum = Int(num)
            }
        }
        
        if roomVnum == nil {
            if let area = areaManager.findArea(byAbbreviatedName: argument) {
                if let originVnum = area.originVnum {
                    roomVnum = originVnum
                } else {
                    roomVnum = area.rooms.first?.vnum
                }
            }
        }
        
        guard let roomVnum = roomVnum else { return false }
        guard let room = db.roomsByVnum[roomVnum] else { return false }
        
        context.objectsAdded += 1
        into = room
        return true
    }
    
    func fetchArgument(from scanner: Scanner,
                       what: CommandArgumentFlags.What,
                       where whereAt: CommandArgumentFlags.Where,
                       cases: GrammaticalCases,
                       condition: ((String) -> Bool)?,
                       intoCreatures: inout [Creature],
                       intoItems: inout [Item],
                       intoRoom: inout Room?,
                       intoString: inout String) -> Bool {
        // Exit early if no argument was requested
        guard what.contains(anyOf: [.creature, .item, .room, .word, .restOfString]) else {
            return false
        }

        // Try to process argument in following order:
        // - as me
        // - items worn / equipped
        // - items in inventory
        // - creatures in room
        // - items in room
        // - creatures in world
        // - items in world
        // - rooms
        // - as word
        // - as rest of string
        
        // Creatures, items and words are described by single word, so try to read one from input:
        let originalScannerIndex = scanner.currentIndex // in case we need to undo word read later
        guard let word = scanner.scanWord(condition: condition) else {
            return false
        }
        
        // - as me
        // FIXME: move all reserved keywords to a class, assign variables to them and don't reference them as text,
        // exclude them from valid names
        if what.contains(.creature) && whereAt.contains(anyOf: [.room, .world]) {
            if fetchSelf(word: word, into: &intoCreatures) {
                return true
            }
        }
        
        let isCountable = what.contains(anyOf: [.creature, .item])
        let isMany = what.contains(.many)
        var context = FetchArgumentContext(word: word, isCountable: isCountable, isMany: isMany)

        // - items worn / equipped
        if what.contains(.item) && whereAt.contains(anyOf: [.equipment, .world]) {
            if fetchItemsInEquipment(context: &context, into: &intoItems, cases: cases) {
                return true
            }
        }
        
        // - items in inventory
        if what.contains(.item) && whereAt.contains(anyOf: [.inventory, .world]) {
            if fetchItemsInInventory(context: &context, into: &intoItems, cases: cases) {
                return true
            }
        }

        // - creatures in room
        if what.contains(.creature) && whereAt.contains(anyOf: [.room, .world]) {
            let isPlayersOnly = what.contains(.playersOnly)
            if fetchCreaturesInRoom(context: &context, into: &intoCreatures, cases: cases, isPlayersOnly: isPlayersOnly) {
                return true
            }
        }

        // - items in room
        if what.contains(.item) && whereAt.contains(anyOf: [.room, .world]) {
            if fetchItemsInRoom(context: &context, into: &intoItems, cases: cases) {
                return true
            }
        }

        // - creatures in area
        if what.contains(.creature) && whereAt.contains(.world) {
            let isPlayersOnly = what.contains(.playersOnly)
            if fetchCreaturesInArea(context: &context, into: &intoCreatures, cases: cases, isPlayersOnly: isPlayersOnly) {
                return true
            }
        }

        // - creatures in world
        if what.contains(.creature) && whereAt.contains(.world) {
            let isPlayersOnly = what.contains(.playersOnly)
            if fetchCreaturesInWorld(context: &context, into: &intoCreatures, cases: cases, isPlayersOnly: isPlayersOnly) {
                return true
            }
        }
        
        // - items in area
        if what.contains(.item) && whereAt.contains(.world) {
            if fetchItemsInArea(context: &context, into: &intoItems, cases: cases) {
                return true
            }
        }

        // - items in world
        if what.contains(.item) && whereAt.contains(.world) {
            if fetchItemsInWorld(context: &context, into: &intoItems, cases: cases) {
                return true
            }
        }

        // - rooms
        if what.contains(.room) && whereAt.contains(.world) {
            if fetchRoom(context: &context, into: &intoRoom) {
                return true
            }
        }

        // - as word
        if what.contains(.word) {
            intoString = word
            return true
        }

        // - as rest of string
        if what.contains(.restOfString) {
            scanner.currentIndex = originalScannerIndex // undo word read
            intoString = scanner.textToParse.trimmingCharacters(in: .whitespaces)
            return true
        }
        
        return true
    }
    
    func sendNothingFound(of what: CommandArgumentFlags.What, where whereAt: CommandArgumentFlags.Where) {
        if what.contains(.creature) && what.contains(.item) {
            send("Здесь нет ничего с таким именем.")
        } else if what.contains(.creature) {
            send("Здесь нет никого с таким именем.")
        } else if what.contains(.item) {
            if whereAt.contains(.room) || whereAt.contains(.world) {
                send("Здесь нет такого предмета.")
            } else if whereAt.contains(.inventory) && !whereAt.contains(.equipment) {
                send("У Вас в руках нет такого предмета.")
            } else {
                send("У Вас нет такого предмета.")
            }
        } else if what.contains(.room) {
            send("Такой комнаты не существует.")
        } else {
            send("Здесь нет ничего с таким именем.")
        }
    }
}
