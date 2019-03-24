import Foundation

enum DamageFormula {
    case noDamage
    case constant(Int)
    case formula1(Int, Int, Int) // 1+2к3
    case formula2(Int, Int, Int, Int) // 1+(2*уровень/3)к4)
    case formula3(Int, Int, Int, Int, Int, Int) // 1+2к3+(4*уровень/5)к6)
}
