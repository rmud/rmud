import Foundation

class BitArray<T: UnsignedInteger> {
    var rawValue: [T]
    
    init(rawValue: [T]) {
        self.rawValue = rawValue
    }
    
    func isSet(bitIndex: Int) -> Bool {
        return isSetAr2D(blockIndex: qField(bitIndex), bitIndex: qNum(bitIndex))
    }
    func set(bitIndex: Int) {
        setBitAr2D(blockIndex: qField(bitIndex), bitIndex: qNum(bitIndex))
    }
    func remove(bitIndex: Int) {
        removeBitAr2D(blockIndex: qField(bitIndex), bitIndex: qNum(bitIndex))
    }
    func toggle(bitIndex: Int) {
        toggleBitAr2D(blockIndex: qField(bitIndex), bitIndex: qNum(bitIndex))
    }
    
    private func qFactor() -> Int { return MemoryLayout<T>.stride * 8 }
    private func qField(_ x: Int) -> Int { return x / qFactor() }
    private func qNum(_ x: Int) -> Int { return x % qFactor() }
    private func vBit(_ x: Int) -> T {
        var val: T = 1
        // Shift `val` left `x` times without knowing T's specific type:
        for _ in 0 ..< x { val *= 2 }
        return val
    }
    private func qBit(_ x: Int) -> T { return vBit(qNum(x)) }
    
    private func isSetAr2D(blockIndex: Int, bitIndex: Int) -> Bool {
        return (rawValue[blockIndex] & vBit(bitIndex)) != 0
    }
    
    private func setBitAr2D(blockIndex: Int, bitIndex: Int) {
        rawValue[blockIndex] |= vBit(bitIndex)
    }
    
    private func removeBitAr2D(blockIndex: Int, bitIndex: Int) {
        rawValue[blockIndex] &= ~vBit(bitIndex)
    }

    private func toggleBitAr2D(blockIndex: Int, bitIndex: Int) {
        rawValue[blockIndex] ^= vBit(bitIndex)
    }
}
