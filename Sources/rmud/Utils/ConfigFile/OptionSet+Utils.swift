import Foundation

public extension OptionSet where RawValue: FixedWidthInteger {
    init(zeroBasedBitIndexes: [Int]) {
        let result = zeroBasedBitIndexes.reduce(UInt64(0)) {
            $0 | 1 << UInt64($1)
        }
        self.init(rawValue: RawValue(result))
    }

    init(oneBasedBitIndexes: [Int]) {
        let result = oneBasedBitIndexes.reduce(UInt64(0)) {
            $0 | 1 << UInt64($1 - 1)
        }
        self.init(rawValue: RawValue(result))
    }

// Returns elements instead of indexes
//    func elements() -> AnySequence<Self> {
//        var remainingBits = rawValue
//        var bitMask: RawValue = 1
//        return AnySequence {
//            return AnyIterator {
//                while remainingBits != 0 {
//                    defer { bitMask = bitMask &* 2 }
//                    if remainingBits & bitMask != 0 {
//                        remainingBits = remainingBits & ~bitMask
//                        return Self(rawValue: bitMask)
//                    }
//                }
//                return nil
//            }
//        }
//    }
}
