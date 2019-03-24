public struct ConfigFileFlags: OptionSet {
    public let rawValue: Int
    
    public static let sortSections  = ConfigFileFlags(rawValue: 1 << 0)
    public static let sortFields = ConfigFileFlags(rawValue: 1 << 1)
    
    public static let defaults: ConfigFileFlags = []

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
