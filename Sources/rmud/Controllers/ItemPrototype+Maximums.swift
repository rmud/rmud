import Foundation

extension ItemPrototype {
    func checkMaximumAndLoadChances() -> Bool {
        return canLoadMore() && checkLoadChances()
    }

    func canLoadMore() -> Bool {
        guard let maximumCountInWorld else {
            return true
        }
        let countInWorld = db.itemsCountByVnum[vnum] ?? 0
        return countInWorld < maximumCountInWorld
    }
    
    func checkLoadChances() -> Bool {
        let loadChance = loadChancePercentage ?? 100
        return Random.probability(loadChance)
    }
}
