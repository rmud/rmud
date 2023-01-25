import Foundation

enum Gender: UInt8 {
    case masculine = 0
    case feminine = 1
    case neuter = 2
    case plural = 3
    case genderNotSpecifiedForCorpse = 0xff // FIXME: shouldn't be here
    
    var singleLetter: String {
        switch self {
        case .masculine: return "м"
        case .feminine: return "ж"
        case .neuter: return "н"
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
            0: "мужской",
            1: "женский",
            2: "средний",
            3: "множественный"
        ])
    }
}
