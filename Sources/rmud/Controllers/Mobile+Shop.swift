import Foundation

extension Mobile {
    func updateShopOnReset() {
        // FIXME
        shopSelloutExtraGoods()
        shopFixMoney()
    }
    
    func shopLoadMenu() {
        guard let shopkeeper = shopkeeper else { return }
        for itemVnum in shopkeeper.producingItemVnums.sorted() {
            guard !creature.carrying.contains(where: { $0.vnum == itemVnum }) else { continue }

            guard let itemPrototype = db.itemPrototypesByVnum[itemVnum] else {
                logError("Shop menu: mobile \(vnum) attempt to load non-existent item \(itemVnum)")
                continue
            }

            guard itemPrototype.checkMaximumAndLoadChances() else { continue }
            
            let item = Item(prototype: itemPrototype, uid: nil, db: db /*, in: homeArea*/)

            item.give(to: creature)
            //obj_enlist_postload(obj); // FIXME: load trigger
        }
    }

    // Продажа магазином на сторону залежалого товара (во время сброса области)
    private func shopSelloutExtraGoods() {
        let itemsCountByVnum: [Int: Int] = shopCountItemsPerItemVnum()
        guard !itemsCountByVnum.isEmpty else { return }
        
        var itemsSold = false
        for (itemVnum, itemCount) in itemsCountByVnum {
            guard let prototype = db.itemPrototypesByVnum[vnum] else {
                logError("Shop sellout goods: non-existent item \(vnum)")
                continue
            }
            
            if prototype.hasType(.spellbook) {
                // Для книг отдельная формула, связанная с их содержимым,
                // и не зависящая от цены и количества таких книг в магазине
                guard let oldestBook = creature.carrying.last(where: { $0.vnum == itemVnum }) else { continue }
                if shopTrySelloutBook(oldestBook) {
                    itemsSold = true
                }
                continue
            }
            
            var chance: Int // where 10000 is 100%
            if itemCount > 1 {
                chance = 10000 * (itemCount - 1) / (2 * shopMaximumItemCountOfSameTypeBeforeSellout)
            } else {
                let baseChance = 30
                let cost = prototype.cost ?? 0
                if cost > 100 {
                    chance = max(1, baseChance - baseChance * cost / 3000)
                } else if cost < 100 {
                    chance = min(150, baseChance * 100 / cost)
                } else {
                    chance = baseChance
                }
                let quality = prototype.qualityPercentage ?? 100
                chance = min(100, max(5, chance * Int(quality) / 100));
            }
            
            if prototype.extraFlags.contains(.tradable) {
                chance += chance / 2
            }
            
            if (prototype.hasType(.treasure) || prototype.hasType(.food) || prototype.hasType(.vessel) || prototype.hasType(.receipt)) // "расходные материалы"
                    || // свитки/бутылки/палки уходят быстро, если их больше двух
                    (itemCount > 2 && (prototype.hasType(.wand) || prototype.hasType(.potion) || prototype.hasType(.scroll) || prototype.hasType(.staff) )) {
                chance += chance / 2
            }
            
            if Int.random(in: 1...10000) <= chance {
                guard let oldestItem = creature.carrying.last(where: { $0.vnum == itemVnum }) else { continue }
                shopSellout(item: oldestItem)
                itemsSold = true
            }
        }
        if itemsSold {
            act("Извинившись, 1и отлучил1(ся,ась,ось,ись), взяв кое-что из товаров, и вскоре вернул1(ся,ась,ось,ись).", .toRoom, .excluding(creature))
        }
    }
    
    // Добавление при сбросе зоны денег в магазин
    private func shopFixMoney() {
        /*
        let startgold = ch->mob->load_gold[0] * (ch->mob->load_gold[1]+1) + ch->mob->load_gold[2];
        if (ch->gold < startgold / 20)
        ch->gold = startgold / 16; // (1/20 + 1/40 ~= 1/13)
        if (ch->gold < startgold / 2)
        ch->gold += ch->gold / 2;
        else if (ch->gold < (startgold * 3) / 4)
        ch->gold += ch->gold / 8;
        /*  else if (ch->gold > startgold * 5)
         ch->gold -= startgold / 2; */
         */
    }
    
    private func shopCountItemsPerItemVnum() -> [Int: Int] {
        guard let shopkeeper = shopkeeper else { return [:] }
        var itemsCountByVnum: [Int: Int] = [:]
        for item in creature.carrying {
            if !item.extraFlags.contains(.noSell) && item.cost > 0 && !shopkeeper.isProducing(item: item) {
                let itemCount = itemsCountByVnum[item.vnum] ?? 0
                itemsCountByVnum[item.vnum] = itemCount + 1
            }
        }
        return itemsCountByVnum
    }
    
    private func shopTrySelloutBook(_ book: Item) -> Bool {
        guard let spellbook = book.asSpellbook() else { return false }
        let spellsCount = spellbook.spellsAndChances.count
        var maximumCircle = 0
        for (spell, _) in spellbook.spellsAndChances {
            // FIXME: possible abuse: buy items shop produces and sell them back many times, they will
            // be never sold out.
            maximumCircle = max(maximumCircle, spell.info.circlesPerClassId[creature.classId] ?? 0)
        }
        if Int.random(in: 1...1000) <= 5 + maximumCircle * 2 + spellsCount * 4 {
            shopSellout(item: book)
            return true
        }
        return false
    }
    
    // продажа магазином предмета насторону
    private func shopSellout(item: Item) {
        creature.gold += Int.random(in: shopSellPrice(item: item)...shopBuyPrice(item: item))
        item.extract(mode: .purgeNothing)
    }

    // Цена продажи игроком в магазин.
    // EXCLUDES condition & repair cost!
    func shopSellPrice(item: Item) -> Int {
        guard let shopkeeper = shopkeeper,
            let buyProfit = shopkeeper.buyProfit else { return 1 }
        let receiptMultiplier = shopIsNotMyReceipt(item: item) ? 1 : 2
        let qualityMultiplier = 50 + Int(item.qualityPercentage)
        let sellPrice = (receiptMultiplier * item.cost * qualityMultiplier * buyProfit) / (2 * 150 * 100)
        return max(1, sellPrice)
    }
    
    // Цена покупки игроком в магазине.
    // EXCLUDES condition & repair cost!
    func shopBuyPrice(item: Item) -> Int {
        guard let shopkeeper = shopkeeper,
            let sellProfit = shopkeeper.sellProfit else { return 1 }
        let spellbookMultiplier = item.isSpellbook() ? 4 : 1
        let qualityMultiplier = 50 + Int(item.qualityPercentage)
        let buyPrice = (spellbookMultiplier * item.cost * qualityMultiplier * sellProfit) / (150 * 100)
        return max(1, buyPrice)
    }
    
    private func shopIsNotMyReceipt(item: Item) -> Bool {
        guard let shopkeeper = shopkeeper else { return false }
        return item.isReceipt() &&
            !(shopkeeper.isProducing(item: item) || isAcceptableReceipt(item: item))
    }
    
}
