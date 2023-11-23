import Foundation

struct NameAndPrice: Hashable {
    var name: String
    var price: Int
}

extension NameAndPrice: Comparable {
    static func <(lhs: NameAndPrice, rhs: NameAndPrice) -> Bool {
        let nameOrdering = lhs.name.caseInsensitiveCompare(rhs.name)
        return nameOrdering == .orderedAscending ||
            (nameOrdering == .orderedSame && lhs.price < rhs.price)
    }
}

extension Creature {
    var isSellingItems: Bool {
        guard let shopkeeper = mobile?.shopkeeper,
              let _ = shopkeeper.sellProfit else { return false }
        return true;
    }
    
    func shopItemsByNameAndPrice() -> [(NameAndPrice, [Item])] {
        let itemsByNameAndPrice: [NameAndPrice: [Item]] = carrying.reduce(into: [:]) {
            (result, item) in
            let price = mobile?.shopBuyPrice(item: item) ?? 1
            let nameAndPrice = NameAndPrice(name: item.nameNominative.full, price: price)
            var items = result[nameAndPrice] ?? []
            items.append(item)
            result[nameAndPrice] = items
        }
        return itemsByNameAndPrice.sorted(by: { $0.key < $1.key })
    }
    
    func shopGetItemByNumber(items: [(NameAndPrice, [Item])], argument: String) -> Item? {
        guard let number = Int(argument) else { return nil }
        let index = number - 1
        return items[safe: index]?.1.first
    }
}
