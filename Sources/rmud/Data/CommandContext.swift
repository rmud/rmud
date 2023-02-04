import Foundation

struct CommandContext {
    var command: Command
    var scanner: Scanner
    var argument1 = ""
    var argument2 = ""
    var creatures1: [Creature] = []
    var creature1: Creature? { return creatures1.first }
    var creatures2: [Creature] = []
    var creature2: Creature? { return creatures2.first }
    var items1: [Item] = []
    var item1: Item? { return items1.first }
    var items2: [Item] = []
    var item2: Item? { return items2.first }
    var room1: Room?
    var room2: Room?
    var subcommand: SubCommand = .none
    var hasArguments: Bool {
        return !creatures1.isEmpty || !creatures2.isEmpty ||
            !items1.isEmpty || !items2.isEmpty ||
            room1 != nil || room2 != nil ||
            !argument1.isEmpty || !argument2.isEmpty
    }

    init(command: Command, scanner: Scanner) {
        self.command = command
        self.scanner = scanner
    }
    
    func scanWord(ignoringFillWords: Bool = false) -> String? {
        // FIXME: ignoringFillWords
        return scanner.scanUpToCharacters(from: CharacterSet.whitespaces)
    }

    func restOfString() -> String {
        return scanner.textToParse.trimmingCharacters(in: CharacterSet.whitespaces)        
    }

    func isSubCommand1(oneOf commands: [String]) -> Bool {
        return argument1.isAbbrev(ofOneOf: commands)
    }
}
