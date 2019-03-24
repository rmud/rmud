import Foundation

// Dice: XdY+Z
struct Dice<T: FixedWidthInteger>: CustomStringConvertible {
    var number: T = 0
    var size: T = 0
    var add: T = 0
    
    var intDice: Dice<Int>? {
        guard let number = Int(exactly: number) else { return nil }
        guard let size = Int(exactly: size) else { return nil }
        guard let add = Int(exactly: add) else { return nil }
        return Dice<Int>(number: number, size: size, add: add)
    }

    var int8Dice: Dice<Int8>? {
        guard let number = Int8(exactly: number) else { return nil }
        guard let size = Int8(exactly: size) else { return nil }
        guard let add = Int8(exactly: add) else { return nil }
        return Dice<Int8>(number: number, size: size, add: add)
    }

    var int64Dice: Dice<Int64>? {
        guard let number = Int64(exactly: number) else { return nil }
        guard let size = Int64(exactly: size) else { return nil }
        guard let add = Int64(exactly: add) else { return nil }
        return Dice<Int64>(number: number, size: size, add: add)
    }

    var description: String {
        if add != 0 {
            // Not '&&' to log '0d5', '5d0' cases otherwise that would be information loss
            if number != 0 || size != 0 {
                return "\(number)к\(size)+\(add)"
            } else {
                return "\(add)"
            }
        } else {
            return "\(number)к\(size)"
        }
    }
    
    func description(for creature: Creature) -> String {
        if add != 0 {
            // Not '&&' to log '0d5', '5d0' cases otherwise that would be information loss
            if number != 0 || size != 0 {
                return "\(creature.bBlu())\(number)\(creature.nNrm())к\(creature.bBlu())\(size)\(creature.nNrm())+\(creature.bBlu())\(add)\(creature.nNrm())"
            } else {
                return "\(creature.bBlu())\(add)\(creature.nNrm())"
            }
        } else {
            return "\(creature.bBlu())\(number)\(creature.nNrm())к\(creature.bBlu())\(size)\(creature.nNrm())"
        }
    }

    init() {
    }

    init(number: T, size: T, add: T = 0) {
        self.number = number
        self.size = size
        self.add = add
    }
    
    init?(_ string: String) {
        let scanner = Scanner(string: string)
        
        guard let v1 = Dice.scanNumberWithoutSign(scanner) else { return nil }
        let hasD = scanner.skipString("к") ||
            scanner.skipString("К") ||
            scanner.skipString("d") ||
            scanner.skipString("D")
        let v2OrNil = Dice.scanNumberWithoutSign(scanner)
        let hasPlus = scanner.skipString("+")
        let v3OrNil = Dice.scanNumberWithoutSign(scanner)
        
        if hasD && v2OrNil == nil { return nil }
        if hasPlus && (v2OrNil == nil || v3OrNil == nil) { return nil }
        
        if v2OrNil == nil && v3OrNil == nil {
            add = v1
        } else {
            number = v1
            size = v2OrNil ?? 0
            add = v3OrNil ?? 0
        }
    }
    
    var isZero: Bool {
        return number == 0 && size == 0 && add == 0
    }
    
    func roll() -> Int {
        var sum = 0
        if size > 0 {
            var rollsLeft = number
            while rollsLeft > 0 {
                sum += Random.uniformInt(0..<Int(size)) + 1
                rollsLeft -= 1
            }
        }
        sum += Int(add)
        return sum
    }
    
    func maximum() -> Int {
        return Int(number) * Int(size) + Int(add)
    }
    
    private static func scanNumberWithoutSign(_ scanner: Scanner) -> T? {
        guard let string = scanner.scanCharacters(from: .decimalDigits) else { return nil }
        return T(string)
    }
}
