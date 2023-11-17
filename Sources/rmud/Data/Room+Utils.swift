import Foundation

extension Room {
    func totalCoinsInRoom(where condition: (_ item: Item) -> Bool = { _ in true }) -> Int {
        var totalCoins = 0
        for item in self.items {
            if let money = item.asMoney() {
                guard condition(item) else { continue }
                totalCoins += money.amount
            }
        }
        return totalCoins
    }
}
