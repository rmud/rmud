import Foundation

extension Dictionary {
    subscript<T: RawRepresentable>(_ key: T) -> Value? where T.RawValue == Key {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue
        }
    }
}
