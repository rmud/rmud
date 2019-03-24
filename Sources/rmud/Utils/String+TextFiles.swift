import Foundation

extension String {
    init(contentsOfFile path: String, encoding enc: String.Encoding, normalizingNewlines: Bool) throws {
        try self.init(contentsOfFile: path, encoding: enc)
        self = self.replacingOccurrences(of: "\r\n", with: "\n")
        self = self.replacingOccurrences(of: "\r", with: "\n")
    }
    
    init(contentsOfTextFile path: String) throws {
        try self.init(contentsOfFile: path, encoding: .utf8, normalizingNewlines: true)
    }
}
