extension Creature {
    func doBuy(context: CommandContext) {
        guard let shopkeeper = chooseShopkeeper() else { return }
        
        if !context.argument1.isEmpty {
            shopBuy(clerk: shopkeeper, name: context.argument1)
        } else {
            send("Что Вы хотите купить?")
        }
    }
    
    private func shopBuy(clerk: Creature, name: String) {
        guard clerk.isSellingItems, let shopkeeper = clerk.mobile?.shopkeeper else {
            act("1и сказал1(,а,о,и) Вам: \"Я ничего не продаю.\"", .to(self), .excluding(clerk))
            return
        }
        
        let itemsByNameAndPrice = clerk.shopItemsByNameAndPrice()
        let item = shopGetItemByNumber(items: itemsByNameAndPrice, argument: name)
        var itemsToSell: [Item] = []
        var createdItems: Set<Item> = []
        if let item = item {
            itemsToSell = [item]
        } else {
            var context = FetchArgumentContext(word: name, isCountable: true, isMany: true)
            let gotAllRequestedItems = clerk.fetchItemsInInventory(context: &context, into: &itemsToSell, cases: .accusative)

            if !gotAllRequestedItems, case .count(let maxItems) = context.targetAmount {
                let itemsToProduce = min(maxItems, shopSellItemCountLimit) - context.currentIndex + 1
                let itemToClone = itemsToSell.last { item in shopkeeper.isProducing(item: item) }
                if let itemToClone = itemToClone, let prototype = db.itemPrototypesByVnum[itemToClone.vnum] {
                    for _ in 0..<itemsToProduce {
                        let item = Item(prototype: prototype, uid: nil, db: db)
                        item.give(to: clerk)
                        createdItems.insert(item)
                    }
                }
            }
        }

        let allItems = itemsToSell + createdItems
        
        guard !allItems.isEmpty else {
            act("1и сказал1(,а,о,и) Вам: \"У меня такого нет.\"",
                .excluding(clerk), .to(self))
            return
        }
        
        let totalPrice = allItems.reduce(0) { current, item in
            current + (clerk.mobile?.shopBuyPrice(item: item) ?? 1)
        }
        act("1и сказал1(,а,о,и) Вам: \"Это будет стоить # монет#(у,ы).\"",
            .excluding(clerk), .to(self), .number(totalPrice));
        
        if gold < totalPrice && !isGodMode() {
            act("1и сказал1(,а,о,и) Вам: \"У Вас не хватает денег.\"",
                .excluding(clerk), .to(self))
            for item in createdItems {
                item.extract(mode: .purgeAllContents)
            }
            return
        }
        
        let stacker = StringStacker()
        
        for item in allItems {
            guard canTake(item: item, isSilent: true) else { continue }
            guard !isAlignmentMismatched(with: item) else { continue }
            
            if !shopkeeper.isProducing(item: item) || createdItems.contains(item) {
                item.removeFromCreature()
                item.give(to: self)
            } else {
                guard let prototype = db.itemPrototypesByVnum[item.vnum] else { continue }
                let clonedItem = Item(prototype: prototype, uid: nil, db: db)
                clonedItem.give(to: self)
            }
            
            let price = clerk.mobile?.shopBuyPrice(item: item) ?? 1
            if !isGodMode() {
                gold -= price
            }
            clerk.gold += price
            
            act("Вы купили у 1р @1в.", .excluding(clerk), .to(self), .item(item)) { target, output in
                stacker.collect(target: target, line: output)
            }
            act("2+и купил2(,а,о,и) у 1+р @1в.", .toRoom, .excluding(clerk), .excluding(self), .item(item)) { target, output in
                stacker.collect(target: target, line: output)
            }
            
            if item.isSpellbook() {
                if let decay = item.decayTimerTicsLeft, decay < 5 {
                    item.decayTimerTicsLeft = 5
                }
            }
        }
        
        stacker.send()
    }
}
