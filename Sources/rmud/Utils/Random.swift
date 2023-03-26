import Foundation

class Random {
    static func probability(_ percentage: some FixedWidthInteger) -> Bool {
        guard percentage < 100 else { return true }
        guard percentage > 0 else  { return false }
        return percentage >= Int.random(in: 1...100)
    }
    
    static func probability(_ percentage: Double) -> Bool {
        guard percentage < 100 else { return true }
        guard percentage > 0 else  { return false }
        return percentage >= Double.random(in: 1...100)
    }
}
