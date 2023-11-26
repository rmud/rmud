import Foundation

extension Creature {
    func ageModifier(for apply: Apply) -> Int {
        guard let player = player else { return 0 }
        var affectedYears = player.affectedAgeYears()
        var modifier = 0
        
        // FIXME сделать в начале рост статов,
        // причём, наверное, сделать это зависимым ещё и от класса
        switch apply {
        case .custom(.strength):
            if affectedYears > 21 &&
                (affectedYears < 29 ||
                 race == .goblin || race == .minotaur ||
                 race == .human || race == .dwarf) {
                modifier = 1
            }
            return modifier - max(0, (affectedYears - 28) / 10) // 38 => -1
        case .custom(.dexterity):
            if (race == .kender || race == .goblin || race == .barbarian) && affectedYears >= 22 {
                modifier = 1
                affectedYears -= 2
            } else if (race == .halfElf && affectedYears >= 24) {
                modifier = 1
                affectedYears -= 4
            }
            return modifier - max(0, (affectedYears - 18) / 10) // 28 => -1
        case .custom(.constitution):
            if (race == .minotaur || race == .dwarf || race == .wildElf) && affectedYears >= 25 {
                modifier = 1
            }
            return modifier - max(0, (affectedYears - 36) / 10) // 46 => -1
        case .custom(.intelligence):
            if (race == .human || race == .highElf || race == .halfElf) && affectedYears >= 25 {
                modifier = 1
            }
            return modifier + max(0, (affectedYears - 25) / (race.isElf ? 12 : 10)) // 36 => +1
        case .custom(.wisdom):
            if ((race == .kender || race.isElf) && affectedYears >= 24 ) {
                modifier = 1;
                affectedYears -= 4;
            } else if (race == .barbarian && affectedYears >= 22) {
                modifier = 1;
                affectedYears -= 2;
            }
            return modifier + max(0, (affectedYears - 18) / (race.isElf ? 12 : 10)) // 28 => +1
        case .custom(.charisma):
            if      affectedYears < 18 { return 0 }
            else if affectedYears < 28 { return 1 }
            else if affectedYears < 36 { return 2 }
            else if affectedYears < 48 { return 1 }
            return (race.isElf || race == .kender) ? 1 : -max(0, (affectedYears - 48) / 8)
        default:
            logError("ageModifier: unknown apply type");
            break
        }
        return 0
    }
}
