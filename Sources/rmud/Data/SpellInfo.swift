import Foundation

struct SpellInfo {
    var name: String
    var pronunciation: String
    var circlesPerClassId: [ClassId: Int]
    var targetWhat: CommandArgumentFlags.What
    var targetWhere: CommandArgumentFlags.Where
    var targetCases: GrammaticalCases
    var aggressive: Bool
    var savingHardness: SpellSavingHardness
    var frag: Frag
    var spellClass: SpellClass
    var damage: DamageFormula
    // (1+(2*level/3)
    var duration: (_ caster: Creature) -> Int
    var durationDecrementMode: Affect.DurationDecrementMode
    var dispells: [Spell]

    init(name: String = "",
        pronunciation: String = "",
        circlesPerClassId: [ClassId: Int] = [:],
        targetWhat: CommandArgumentFlags.What = [],
        targetWhere: CommandArgumentFlags.Where = [],
        targetCases: GrammaticalCases = [.accusative],
        aggressive: Bool = false,
        savingHardness: SpellSavingHardness = .normal,
        frag: Frag = .magic,
        spellClass: SpellClass = .neutral,
        damage: DamageFormula = .noDamage,
        duration: @escaping (_ caster: Creature) -> Int = { _ in return 0 },
        durationDecrementMode: Affect.DurationDecrementMode = .everyMinute,
        dispells: [Spell] = []) {
        self.name = name
        self.pronunciation = pronunciation
        self.circlesPerClassId = circlesPerClassId
        self.targetWhat = targetWhat
        self.targetWhere = targetWhere
        self.targetCases = targetCases
        self.aggressive = aggressive
        self.savingHardness = savingHardness
        self.frag = frag
        self.spellClass = spellClass
        self.damage = damage
        self.duration = duration
        self.durationDecrementMode = durationDecrementMode
        self.dispells = dispells
    }
}
