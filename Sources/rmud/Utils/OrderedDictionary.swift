import Foundation

public class OrderedDictionary<Key: Hashable, Value> {
    private var valuesByKey = [Key: Value]()
    public private(set) var orderedKeys = [Key]()
    
    public var isEmpty: Bool { return valuesByKey.isEmpty }
    
    public init() {
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return valuesByKey[key]
        }
        set {
            if let value = newValue {
                if nil == updateValue(value, forKey: key) {
                    valuesByKey[key]  = value
                    orderedKeys.append(key)
                }
            } else {
                if nil != valuesByKey.removeValue(forKey: key) {
                    orderedKeys = orderedKeys.filter { $0 != key }
                }
            }
        }
    }
    
    @discardableResult
    public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        return valuesByKey.updateValue(value, forKey: key)
    }
    
    @discardableResult
    public func removeValue(forKey key: Key) -> Value? {
        if let value = valuesByKey.removeValue(forKey: key) {
            orderedKeys = orderedKeys.filter { $0 != key }
            return value
        }
        return nil
    }
    
    public func removeAll(keepingCapacity: Bool) {
        valuesByKey.removeAll(keepingCapacity: keepingCapacity)
        orderedKeys.removeAll(keepingCapacity: keepingCapacity)
    }
}
