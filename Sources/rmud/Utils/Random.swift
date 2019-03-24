import Foundation
#if os(Linux)
import BSD
#endif

class Random {
    // Uniform random number in range [0, to)
    static func uniformInt(excludingTo: Int) -> Int {
        return Int(arc4random_uniform(UInt32(excludingTo)))
    }
    
    static func uniformInt(_ range: CountableRange<Int>) -> Int {
        let count = UInt32(range.upperBound - range.lowerBound)
        return Int(arc4random_uniform(count)) + range.lowerBound
    }
    
    static func uniformInt(_ range: CountableClosedRange<Int>) -> Int {
        let count = UInt32(range.upperBound + 1 - range.lowerBound)
        return Int(arc4random_uniform(count)) + range.lowerBound
    }
    
    static func uniformBool() -> Bool {
        return uniformInt(0...1) != 0
    }

}
