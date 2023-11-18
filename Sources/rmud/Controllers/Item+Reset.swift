import Foundation

extension Item {
    func loadContents(from outerPrototype: ItemPrototype) {
        for (vnum, count) in outerPrototype.contentsToLoadCountByVnum.sorted(by: { $0.0 < $1.0 }) {
            guard let prototype = db.itemPrototypesByVnum[vnum] else {
                logError("Reset zone: item \(vnum) does not exist")
                logToMud("Предмет \(vnum) не существует", verbosity: .complete)
                continue
            }

            for _ in 0 ..< count {
                guard prototype.canLoadMore() else { break }
                guard prototype.checkLoadChances() else { continue }
                
                let item = Item(prototype: prototype, uid: nil, db: db)
                item.put(into: self)
                
                item.loadContents(from: prototype)
            }
        }
    }
}
