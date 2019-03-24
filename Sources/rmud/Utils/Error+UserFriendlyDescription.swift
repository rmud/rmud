import Foundation

extension Error {
    var userFriendlyDescription: String {
        var text: String
        if _domain == NSPOSIXErrorDomain {
            text = String(cString: strerror(Int32(_code)))
        } else {
            return localizedDescription
        }
        if let userInfo = _userInfo {
            text += " (domain: \(_domain), code: \(_code), userInfo: \(userInfo))"
        } else {
            text += " (domain: \(_domain), code: \(_code))"
        }
        return text
    }
}
