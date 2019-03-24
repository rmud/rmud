public struct FastCharacterSet {
    public static let decimalDigits = FastCharacterSet([48, 49, 50, 51, 52, 53, 54, 55, 56, 57])
    public static let empty = FastCharacterSet([])
    public static let plusMinusCharacterSet = FastCharacterSet([43, 45])
    public static let newlines = FastCharacterSet([13, 10])
    public static let whitespaces = FastCharacterSet([9, 32])
    public static let whitespacesAndNewlines = FastCharacterSet([9, 32, 13, 10])
    
    private var v1: UInt64 = 0
    private var v2: UInt64 = 0
    private var v3: UInt64 = 0
    private var v4: UInt64 = 0

    public var inverted: FastCharacterSet {
        return FastCharacterSet(v1: ~v1, v2: ~v2, v3: ~v3, v4: ~v4)
    }
    
    public init(_ bytes: [UInt8]) {
        for byte in bytes {
            if byte < 64 {
                v1 |= 1 << UInt64(byte)
            } else if byte < 128 {
                v2 |= 1 << UInt64(byte - 64)
            } else if byte < 192 {
                v3 |= 1 << UInt64(byte - 128)
            } else {
                v4 |= 1 << UInt64(byte - 192)
            }
        }
    }
    
    public init(string: String) {
        let bytes = [UInt8](string.utf8)
        self.init(bytes)
    }
    
    private init(v1: UInt64, v2: UInt64, v3: UInt64, v4: UInt64) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        self.v4 = v4
    }
    
    public func union(_ set: FastCharacterSet) -> FastCharacterSet {
        return FastCharacterSet(v1: v1 | set.v1,
            v2: v2 | set.v2,
            v3: v3 | set.v3,
            v4: v4 | set.v4)
    }
    
    public func contains(_ byte: UInt8) -> Bool {
        if byte < 64 {
            return 0 != (v1 & (1 << UInt64(byte)))
        } else if byte < 128 {
            return 0 != (v2 & (1 << UInt64(byte - 64)))
        } else if byte < 192 {
            return 0 != (v3 & (1 << UInt64(byte - 128)))
        } else {
            return 0 != (v4 & (1 << UInt64(byte - 192)))
        }
    }
}

extension FastCharacterSet: Equatable {
    public static func ==(lhs: FastCharacterSet, rhs: FastCharacterSet) -> Bool {
        return lhs.v1 == rhs.v1 &&
            lhs.v2 == rhs.v2 &&
            lhs.v3 == rhs.v3 &&
            lhs.v4 == rhs.v4
    }
}
