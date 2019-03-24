import Foundation

extension Array {
    subscript (validating index: Int) -> Element? {
        return index >= 0 && index < count ? self[index] : nil
    }
}

// https://christiantietze.de/posts/2017/06/last-where/
extension BidirectionalCollection
where Self.Indices.Iterator.Element == Self.Index {
    
    func last(
        where predicate: (Self.Iterator.Element) throws -> Bool
        ) rethrows -> Self.Iterator.Element? {
        
        for index in self.indices.reversed() {
            let element = self[index]
            if try predicate(element) {
                return element
            }
        }
        
        return nil
    }
}
