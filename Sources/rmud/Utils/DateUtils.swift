import Foundation

struct DateUtils {
    static private let dateFormatterForTimeT: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }()
    
    static func formatTimeT(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return dateFormatterForTimeT.string(from: date)
    }
}
    
