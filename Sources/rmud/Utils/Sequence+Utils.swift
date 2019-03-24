import Foundation

extension Sequence {
    func count(where condition: (Element)->Bool) -> Int {
        //return reduce(0) { condition($1) ? $0 + 1 : $0 }
        // Optimize:
        var accumulator = 0
        for element in self {
            if condition(element) {
                accumulator += 1
            }
        }
        return accumulator
    }
}

public struct Zip2WithNilPadding<T: Sequence, U: Sequence>: Sequence {
    public typealias Iterator = AnyIterator<(T.Iterator.Element?, U.Iterator.Element?)>
    
    public let first: T
    public let second: U
    
    public init(_ first: T, _ second: U) {
        self.first = first
        self.second = second
    }
    
    public func makeIterator() -> Iterator {
        var iterator1: T.Iterator? = first.makeIterator()
        var iterator2: U.Iterator? = second.makeIterator()
        
        return Iterator() {
            let element1 = iterator1?.next()
            let element2 = iterator2?.next()
            
            if element1 == nil && element2 == nil {
                return nil
            } else {
                return (element1, element2)
            }
        }
    }
}
