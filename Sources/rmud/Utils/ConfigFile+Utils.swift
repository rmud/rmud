import Foundation

extension ConfigFile {
    subscript (_ section: String, _ name: String) -> String? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> Int? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> Int8? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> Int16? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> Int32? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> Int64? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> UInt? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> UInt8? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> UInt16? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> UInt32? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> UInt64? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> Bool? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> Double? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> Float? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript (_ section: String, _ name: String) -> Character? {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
    
    subscript <T: OptionSet>(_ section: String, _ name: String) -> T? where T.RawValue: FixedWidthInteger, T.Element == T {
        get { return get("\(section).\(name)") }
        set { set("\(section).\(name)", newValue) }
    }
}
