import Foundation

enum Gender: UInt8 {
    case neuter = 0
    case masculine = 1
    case feminine = 2
    case plural = 3
    case genderNotSpecifiedForCorpse = 0xff // FIXME: shouldn't be here
    
    var singleLetter: String {
        switch self {
        case .neuter: return "н"
        case .masculine: return "м"
        case .feminine: return "ж"
        case .plural: return "*"
        case .genderNotSpecifiedForCorpse: return "т"
        }
    }
    
    func ending(_ endingsPerGender: String) -> String {
        let endings = endingsPerGender.split(separator: ",", omittingEmptySubsequences: false)
        return String(endings[safe: Int(rawValue)] ?? "")
    }
    
    static let aliases = ["род", "пол", "труп.род"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0: "средний",
            1: "мужской",
            2: "женский",
            3: "множественный"
        ])
    }
}
