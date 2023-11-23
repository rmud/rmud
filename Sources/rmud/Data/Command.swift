import Foundation

struct Command {
    typealias Handler = (_ creature: Creature) -> (_ context: CommandContext) -> ()
    
    var aliases: [String]
    var group: CommandGroup
    var flags: CommandFlags
    
    var minimumPosition: Position
    var roles: Roles
    var skill: Skill?

    var arg1What: CommandArgumentFlags.What
    var arg1Where: CommandArgumentFlags.Where
    var arg1Cases: GrammaticalCases
    var arg2What: CommandArgumentFlags.What
    var arg2Where: CommandArgumentFlags.Where
    var arg2Cases: GrammaticalCases
    
    var handler: Handler?

    init(_ aliases: [String],
        group: CommandGroup,
        _ handler: Handler?,
        
        flags: CommandFlags = [],
         
        minPosition: Position = .standing,
        roles: Roles = [],
        skill: Skill? = nil,
         
        arg1 arg1What: CommandArgumentFlags.What = [],
        cases1 arg1Cases: GrammaticalCases = [],
        where1 arg1Where: CommandArgumentFlags.Where = [],
        arg2 arg2What: CommandArgumentFlags.What = [],
        cases2 arg2Cases: GrammaticalCases = [],
        where2 arg2Where: CommandArgumentFlags.Where = []
    ) {
        self.aliases = aliases
        self.group = group
        self.flags = flags
        self.minimumPosition = minPosition
        self.roles = roles
        self.skill = skill
        self.arg1What = arg1What
        self.arg1Where = arg1Where
        self.arg1Cases = arg1Cases
        self.arg2What = arg2What
        self.arg2Where = arg2Where
        self.arg2Cases = arg2Cases
        self.handler = handler
    }
    
    func canRunWithRoles(_ creatureRoles: Roles) -> Bool {
        guard roles.isEmpty ||
                !roles.intersection(creatureRoles).isEmpty else {
            return false
        }
        return true
    }
}
