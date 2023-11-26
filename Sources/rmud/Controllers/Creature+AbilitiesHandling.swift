import Foundation

extension Creature {
    func rollStartAbilities() {
        realStrength = 13
        realDexterity = 13
        realConstitution = 13
        realIntelligence = 13
        realWisdom = 13
        realCharisma = 13

        let raceInfo = race.info
        let classInfo = classId.info
        
        realSize = raceInfo.size
        realMaximumMovement = raceInfo.movement
        
        switch gender {
        case .masculine:
            height = raceInfo.heightMale
            weight = raceInfo.weightMale
        case .feminine:
            height = raceInfo.heightFemale
            weight = raceInfo.weightFemale
        default:
            assertionFailure()
            break
        }
        
        height += UInt(Dice(number: raceInfo.heightDiceNum, size: raceInfo.heightDiceSize).roll())
        weight += UInt(Dice(number: raceInfo.weightDiceNum, size: raceInfo.weightDiceSize).roll())
        
        realStrength = UInt8(Int(realStrength) + raceInfo.strength + classInfo.strength)
        realDexterity = UInt8(Int(realDexterity) + raceInfo.dexterity + classInfo.dexterity)
        realConstitution = UInt8(Int(realConstitution) + raceInfo.constitution + classInfo.constitution)
        realIntelligence = UInt8(Int(realIntelligence) + raceInfo.intelligence + classInfo.intelligence)
        realWisdom = UInt8(Int(realWisdom) + raceInfo.wisdom + classInfo.wisdom)
        realCharisma = UInt8(Int(realCharisma) + raceInfo.charisma /* + classInfo.charisma */)
    }

    // FIXME: move to data/classes
    private static let abilityWeightsPerClass: [ClassId: [UInt8]] = {
        var result: [ClassId: [UInt8]] = [:]
        //                     S  D  C  I  W
        result[.mage]       = [2, 4, 5, 8, 5] // 24
        result[.mishakal]   = [2, 4, 3, 7, 8] // 24
        result[.thief]      = [6, 8, 3, 3, 4] // 24
        result[.fighter]    = [7, 6, 7, 2, 2] // 24
        result[.assassin]   = [7, 7, 4, 3, 3] // 24
        result[.ranger]     = [7, 7, 6, 2, 2] // 24
        result[.solamnic]   = [7, 5, 6, 3, 4] // 25
        result[.morgion]    = [2, 5, 2, 7, 8] // 24
        result[.chislev]    = [2, 4, 3, 7, 8] // 24
        result[.sargonnas]  = [2, 4, 3, 7, 8] // 24
        result[.kiriJolith] = [2, 4, 3, 7, 8] // 24
        return result
    }()

    func rollRealAbilities() {
        guard level >= 3 else { return }
        let rollBasicAbility = {
            UInt8(
                Dice(number: 4, size: 4).roll() + Int.random(in: 2...4)
            )
        }
        
        let areAbilitiesPlayable: ()->Bool = {
            guard let abilityWeights = Creature.abilityWeightsPerClass[self.classId] else {
                fatalError("Ability weights not defined for class \(self.classId.rawValue)")
            }
            var abilities: [UInt8] = []
            abilities.append(self.realStrength)
            abilities.append(self.realDexterity)
            abilities.append(self.realConstitution)
            abilities.append(self.realIntelligence)
            abilities.append(self.realWisdom)
            assert(abilities.count == abilityWeights.count)

            var sum = 0
            for i in 0 ..< abilities.count {
                // проверка на минимальное значение характеристики
                // оно равно 5 + (abil_weight[class][stat]-2)*2,
                // что даёт нам 5 для тех,у кого в таблице 2, 9 - для 4,
                // 13 - для 6, 15 для 7 и 17 для 8
                guard abilities[i] - 5 >= (abilityWeights[i] - 2) * 2 else { return false }
                sum += (Int(abilities[i]) - 13) * Int(abilityWeights[i])
            }
            
            return sum >= 58;
        }
        
        let raceInfo = race.info
        let classInfo = classId.info

        repeat {
            realStrength = rollBasicAbility()
            realDexterity = rollBasicAbility()
            realConstitution = rollBasicAbility()
            realIntelligence = rollBasicAbility()
            realWisdom = rollBasicAbility()
            
            realStrength = UInt8(Int(realStrength) + raceInfo.strength + classInfo.strength)
            realDexterity = UInt8(Int(realDexterity) + raceInfo.dexterity + classInfo.dexterity)
            realConstitution = UInt8(Int(realConstitution) + raceInfo.constitution + classInfo.constitution)
            realIntelligence = UInt8(Int(realIntelligence) + raceInfo.intelligence + classInfo.intelligence)
            realWisdom = UInt8(Int(realWisdom) + raceInfo.wisdom + classInfo.wisdom)
            
            realStrength = realStrength.clamped(to: 1...30)
            realDexterity = realDexterity.clamped(to: 1...30)
            realConstitution = realConstitution.clamped(to: 1...30)
            realIntelligence = realIntelligence.clamped(to: 1...30)
            realWisdom = realWisdom.clamped(to: 1...30)
        } while !areAbilitiesPlayable()
    }
}
