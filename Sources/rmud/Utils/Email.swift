import Foundation

class Email {
    static func isValidEmail(_ email: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,6}$",
                                             options: [.caseInsensitive])
        return regex.firstMatch(in: email, options: [],
                                range: NSMakeRange(0, email.utf16.count)) != nil
    }
}
