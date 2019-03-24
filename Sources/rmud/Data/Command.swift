import Foundation

struct Command {
    typealias Handler = (_ creature: Creature) -> (_ context: CommandContext) -> ()
    
    var aliases: [String]
    var subcommand: SubCommand
    var flags: CommandFlags
    
    var minimumPosition: Position
    var minimumLevel: UInt8
    var skill: Skill?

    var arg1What: CommandArgumentFlags.What
    var arg1Where: CommandArgumentFlags.Where
    var arg1Cases: GrammaticalCases
    var arg1Extra: CommandArgumentFlags.Extra
    var arg2What: CommandArgumentFlags.What
    var arg2Where: CommandArgumentFlags.Where
    var arg2Cases: GrammaticalCases
    var arg2Extra: CommandArgumentFlags.Extra
    
    var handler: Handler

    init(_ aliases: [String],
        subcommand: SubCommand = .none,
        _ handler: @escaping Handler,
        
        flags: CommandFlags = [],
         
        minPosition: Position = .standing,
        minLevel: UInt8 = 0,
        skill: Skill? = nil,
         
        arg1 arg1What: CommandArgumentFlags.What = [],
        cases1 arg1Cases: GrammaticalCases = [],
        where1 arg1Where: CommandArgumentFlags.Where = [],
        extra1 arg1Extra: CommandArgumentFlags.Extra = [],
        arg2 arg2What: CommandArgumentFlags.What = [],
        cases2 arg2Cases: GrammaticalCases = [],
        where2 arg2Where: CommandArgumentFlags.Where = [],
        extra2 arg2Extra: CommandArgumentFlags.Extra = []
        ) {
        self.aliases = aliases
        self.subcommand = subcommand
        self.flags = flags
        self.minimumPosition = minPosition
        self.minimumLevel = minLevel
        self.skill = skill
        self.arg1What = arg1What
        self.arg1Where = arg1Where
        self.arg1Cases = arg1Cases
        self.arg1Extra = arg1Extra
        self.arg2What = arg2What
        self.arg2Where = arg2Where
        self.arg2Cases = arg2Cases
        self.arg2Extra = arg2Extra
        self.handler = handler
    }
}
