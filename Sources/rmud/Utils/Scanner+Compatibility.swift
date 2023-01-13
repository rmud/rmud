import Foundation

extension Scanner {
    public func scanInteger() -> Int? {
        var result: Int = 0
        return scanInt(&result) ? result : nil
    }

    public func scanInt64() -> Int64? {
        var result: Int64 = 0
        return scanInt64(&result) ? result : nil
    }

    public func scanUInt64() -> UInt64? {
        var result: UInt64 = 0
        return scanUnsignedLongLong(&result) ? result : nil
    }
    
    public func scanHexUInt64() -> UInt64? {
        var result: UInt64 = 0
        return scanHexInt64(&result) ? result : nil
    }

    public func scanHexFloat() -> Float? {
        var result: Float = 0.0
        return scanHexFloat(&result) ? result : nil
    }

    public func scanHexDouble() -> Double? {
        var result: Double = 0.0
        return scanHexDouble(&result) ? result : nil
    }
}


