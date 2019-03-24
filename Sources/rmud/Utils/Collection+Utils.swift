import Foundation

extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return index >= startIndex && index < endIndex ? self[index] : nil
    }
}

// https://stackoverflow.com/questions/48449365/how-to-determine-longest-common-prefix-and-suffix-for-array-of-strings
extension Collection where Element: StringProtocol {
    func longestCommonPrefix() -> String {
        guard let first = self.first.map({ String($0) }) else { return "" }
        return dropFirst().reduce(first, { $0.commonPrefix(with: $1) })
    }
    
    func longestCommonSuffix() -> String {
        return String(self.lazy.map({ String($0.reversed()) }).longestCommonPrefix().reversed())
    }
}

