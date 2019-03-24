import Foundation

extension Int {
    func ending(_ ending1: String, _ ending2: String, _ ending3: String) -> String {
        var val = self
        if val < 0 {
            val = -val
        }
        val %= 100
        if val > 20 {
            val %= 10
        }
        return val == 1 ? ending1 : ((val >= 2 && val <= 4) ? ending2 : ending3)
    }
}

extension Int16 {
    func ending(_ ending1: String, _ ending2: String, _ ending3: String) -> String {
        return Int(self).ending(ending1, ending2, ending3)
    }
}

extension UInt8 {
    func ending(_ ending1: String, _ ending2: String, _ ending3: String) -> String {
        return Int(self).ending(ending1, ending2, ending3)
    }
}
