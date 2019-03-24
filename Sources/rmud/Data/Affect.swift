import Foundation

class Affect
{
    enum DurationDecrementMode: UInt8 {
        case everyMinute = 0
        case everyCombatRound = 1
        // every mobile pulse when not in combat
        case everyCombatRoundOrMobilePulse = 2
    }
    
    init(type: AffectType,
         level: Int8 = 0,
         duration: Int16 = 0,
         decrement: DurationDecrementMode = .everyMinute,
         apply: Apply = .none,
         modifier: Int8 = 0,
         sourceUid: UInt64 = 0) {
        self.type = type
        self.level = level
        self.duration = duration
        self.decrement = decrement
        self.apply = apply
        self.modifier = modifier
        self.sourceUid = sourceUid
    }

    var type: AffectType // Skill or spell
    var level: Int8 = 0 // Level of spell
    var duration: Int16 = 0 // For how long its effects will last
    var decrement: DurationDecrementMode = .everyMinute
    var modifier: Int8 = 0 // This is added to apropriate ability
    var apply: Apply = .none // Tells which ability to change
    var sourceUid: UInt64 = 0 // TODO uid существа или предмета, наложившего эффект
}

