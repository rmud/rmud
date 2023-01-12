import Foundation

class SpellsFileParser {
    private enum State {
        case getSpellIndex
        case getSpellName
        case getSpellPronunciation
        case getCircles
        case getTarget
        case getAggressivenessAndSaveHardness
        case getFragType
        case getSpellClassAndSchool
        case getDamage
        case getDurationAndDurationDecrementMode
        case getDispells
    }

    let filename: String

    private var state: State = .getSpellIndex
    private var spellInfo: SpellInfo?
    
    init(filename: String) {
        self.filename = filename
    }
    
    func parse() throws {
        let data = try String(contentsOfFile: filename, encoding: .utf8)
        
        data.forEachLine { index, line, stop in
            let processed = trimCommentsAndSpacing(in: line, commentStart: ";")
            guard !processed.isEmpty else { return }
            
            switch state {
            case .getSpellIndex:
                guard let spellIndex = UInt16(line) else {
                    logFatal("\(filename):\(index): spell number expected")
                }
                guard let spell = Spell(rawValue: spellIndex) else {
                    logFatal("\(filename):\(index): spell does not exist: \(spellIndex)")
                }
                spellInfo = spells.getSpellInfo(for: spell)
                state = .getSpellName
            case .getSpellName:
                spellInfo?.name = processed == "." ? "" : processed
                state = .getSpellPronunciation
            case .getSpellPronunciation:
                spellInfo?.pronunciation = processed == "." ? "" : processed
                state = .getCircles
            case .getCircles:
                let circles = processed.components(separatedBy: CharacterSet.whitespaces).filter({ !$0.isEmpty }).map { Int($0) ?? 0 }
                guard circles.count == ClassId.count else {
                    logFatal("\(filename):\(index): expected \(ClassId.count) spell circles, got \(circles.count)")
                }
                for (classIndex, circle) in circles.enumerated() {
                    guard let classIdValue = UInt8(exactly: classIndex),
                        let classId = ClassId(rawValue: classIdValue) else {
                        logFatal("\(filename):\(index): invalid class id")
                    }
                    guard circle != 0 else { continue }
                    spellInfo?.circlesPerClassId[classId] = circle
                }
                state = .getTarget
            case .getTarget:
                let flags = processed.components(separatedBy: CharacterSet.whitespaces).filter({ !$0.isEmpty }).map { Int($0) ?? -1 }
                if flags.count == 1 && flags[0] == -1 {
                    spellInfo?.targetWhat = []
                    spellInfo?.targetWhere = []
                    return
                }
                for flag in flags {
                    switch flag {
                    case 0: spellInfo?.targetWhat.insert(.item)
                    case 1: spellInfo?.targetWhat.insert(.creature)
                    case 3: spellInfo?.targetWhat.insert(.playersOnly)
                    case 4: spellInfo?.targetWhat.insert(.word)
                    case 5: spellInfo?.targetWhat.insert(.many)
                    case 6: spellInfo?.targetWhere.insert(.equipment)
                    case 7: spellInfo?.targetWhere.insert(.inventory)
                    case 8: spellInfo?.targetWhere.insert(.room)
                    case 9: spellInfo?.targetWhere.insert(.world)
                    default:                     logFatal("\(filename):\(index): unknown target flag \(flag)")

                    }
                }
                spellInfo?.targetCases = .accusative
                state = .getAggressivenessAndSaveHardness
            case .getAggressivenessAndSaveHardness:
                let values = processed.components(separatedBy: CharacterSet.whitespaces).filter { !$0.isEmpty }
                guard values.count <= 2 else {
                    logFatal("\(filename):\(index): expected 1 or 2 values: aggressiveness and optional saving hardness, got \(values.count) values")
                }
                spellInfo?.aggressive = Int(values[validating: 0] ?? "0") != 0 ? true : false
                spellInfo?.savingHardness = SpellSavingHardness(rawValue: UInt8(values[validating: 1] ?? "0") ?? 0) ?? .normal
                if spellInfo?.savingHardness == .impossible {
                    logFatal("\(filename):\(index): saving hardness can only be 0, 1 or 2")
                }
                state = .getFragType
            case .getFragType:
                spellInfo?.frag = Frag(rawValue: UInt8(processed) ?? 0) ?? .magic
                state = .getSpellClassAndSchool
            case .getSpellClassAndSchool:
                let values = processed.components(separatedBy: CharacterSet.whitespaces).filter{ !$0.isEmpty }
                guard values.count >= 1 && values.count <= 2 else {
                    logFatal("\(filename):\(index): expected 1 or 2 values: spell class and school, got \(values.count) values")
                }
                spellInfo?.spellClass = SpellClass(rawValue: UInt8(values[validating: 1] ?? "0") ?? 0) ?? .neutral
                //spellInfo?.school = ...unused...
                state = .getDamage
            case .getDamage:
                let values = processed.components(separatedBy: CharacterSet.whitespaces).filter({ !$0.isEmpty }).map { Int($0) ?? 0 }
                switch values.count {
                case 1: spellInfo?.damage = .constant(values[0])
                case 3: spellInfo?.damage = .formula1(values[0], values[1], values[2])
                case 4: spellInfo?.damage = .formula2(values[0], values[1], values[2], values[3])
                case 6: spellInfo?.damage = .formula3(values[0], values[1], values[2], values[3], values[4], values[5])
                default:
                    logFatal("\(filename):\(index): invalid damage formula format")
                }
                state = .getDurationAndDurationDecrementMode
            case .getDurationAndDurationDecrementMode:
                 // durationDecrementMode was troolean value called combatSpell
                let values = processed.components(separatedBy: CharacterSet.whitespaces).filter({ !$0.isEmpty })
                guard values.count == 4 else {
                    logFatal("\(filename):\(index): expected duration (3 numbers) and duration decrement mode")
                }
                spellInfo?.duration = { caster in
                    let v1 = Int(values[validating: 0] ?? "0") ?? 0
                    let v2 = Int(values[validating: 1] ?? "0") ?? 0
                    let v3 = Int(values[validating: 2] ?? "1") ?? 1
                    return v1 + v2 * Int(caster.level) / v3
                }
                spellInfo?.durationDecrementMode = Affect.DurationDecrementMode(rawValue: UInt8(values[validating: 3] ?? "0") ?? 0) ?? .everyMinute
                state = .getDispells
            case .getDispells:
                let values = processed.components(separatedBy: CharacterSet.whitespaces).filter({ !$0.isEmpty })
                spellInfo?.dispells = values.compactMap {
                    guard let spellIndex = UInt16($0) else {
                        logFatal("\(filename):\(index): spell number expected")
                    }
                    guard spellIndex != 0 else { return nil }
                    guard let spell = Spell(rawValue: spellIndex) else {
                        logFatal("\(filename):\(index): spell does not exist: \(spellIndex)")
                    }
                    return spell
                }
                //state = .getNextAffect
            //case .getNextAffect:
                

            }
        }
    }
    

}
