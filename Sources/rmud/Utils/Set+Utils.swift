import Foundation

extension SetAlgebra {
    public func contains(anyOf other: Self) -> Bool {
        return !isDisjoint(with: other)
    }
}
