import Foundation

public extension ConfigFile {
    subscript (_ name: String) -> String? {
        get { return get(name) }
        set { set(name, newValue) }
    }
    
    subscript (_ name: String) -> Int? {
        get { return get(name) }
        set { set(name, newValue) }
    }
    
    subscript (_ name: String) -> Int8? {
        get { return get(name) }
        set { set(name, newValue) }
    }

    subscript (_ name: String) -> Int16? {
        get { return get(name) }
        set { set(name, newValue) }
    }

    subscript (_ name: String) -> Int32? {
        get { return get(name) }
        set { set(name, newValue) }
    }

    subscript (_ name: String) -> Int64? {
        get { return get(name) }
        set { set(name, newValue) }
    }

    subscript (_ name: String) -> UInt? {
        get { return get(name) }
        set { set(name, newValue) }
    }
    
    subscript (_ name: String) -> UInt8? {
        get { return get(name) }
        set { set(name, newValue) }
    }
    
    subscript (_ name: String) -> UInt16? {
        get { return get(name) }
        set { set(name, newValue) }
    }
    
    subscript (_ name: String) -> UInt32? {
        get { return get(name) }
        set { set(name, newValue) }
    }
    
    subscript (_ name: String) -> UInt64? {
        get { return get(name) }
        set { set(name, newValue) }
    }
    
    subscript (_ name: String) -> Bool? {
        get { return get(name) }
        set { set(name, newValue) }
    }

    subscript (_ name: String) -> Double? {
        get { return get(name) }
        set { set(name, newValue) }
    }

    subscript (_ name: String) -> Float? {
        get { return get(name) }
        set { set(name, newValue) }
    }

    subscript (_ name: String) -> Character? {
        get { return get(name) }
        set { set(name, newValue) }
    }
    
    subscript <T: OptionSet>(_ name: String) -> T? where T.RawValue: FixedWidthInteger, T.Element == T {
        get { return get(name) }
        set { set(name, newValue) }
    }
}
