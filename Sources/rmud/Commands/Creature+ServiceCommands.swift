import Foundation
import OrderedCollections

private struct NameAndPrice: Hashable {
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
    private enum ServiceType {
        case shop
        case stable
        case bank
        case inn
        case post
    }
    
    func doService(context: CommandContext) {
        let serviceType: ServiceType
        
        switch context.subcommand {
        case .shopList, .shopBuy, .shopRepair, .shopEvaluate, .shopSell, .shopEstimate, .shopBrowse:
            serviceType = .shop
        default:
            send("Данный вид услуги здесь не предоставляется.")
            logError("doService(): unsupported subcommand \(context.subcommand)")
            assertionFailure()
            return
        }

        guard let clerk = inRoom?.creatures.first(where: { clerk in
            return clerk.isMobile && canSee(clerk) &&
                ((serviceType == .shop && clerk.mobile?.shopkeeper != nil) /* ||
                    (type == SERV_STABLE && clerk->mob->stableman != 0) ||
                    (type == SERV_BANK && MOB_FLAGGED(clerk, MOB_BANKER)) ||
                    (type == SERV_INN && MOB_FLAGGED(clerk, MOB_RECEPTIONIST)) ||
                    (type == SERV_POST && MOB_FLAGGED(clerk, MOB_POSTMASTER))*/)

        }) else {
            let message: String
            message = "Здесь нет продавцов."
            /*
            switch serviceType {
            case .shop: message = "Здесь нет продавцов."
            case .stable: message = "Здесь нет конюхов."
            case .bank: message = "Здесь нет банкиров."
            case .inn: message = "Здесь нет владельцев гостиницы."
            case .post: message = "Здесь нет почтальонов."
            }
            */
            send(message)
            return
        }
        
        guard clerk.isAwake && !clerk.isHeld() else {
            act("2и сейчас не в состоянии Вас обслужить.", .toCreature(self), .excludingCreature(clerk))
            return
        }
        
        guard serviceType == .inn || clerk.canSee(self) else {
            act("1и произнес1(,ла,ло,ли): \"Я не обслуживаю тех, кого не вижу!\"", .toRoom, .excludingCreature(clerk))
            return
        }

        
        switch context.subcommand {
        case .shopList:
            shopList(clerk: clerk, filter: context.argument1)
        case .shopBuy:
            if !context.argument1.isEmpty {
                shopBuy(clerk: clerk, name: context.argument1)
            } else {
                send("Что Вы хотите купить?")
            }
        default:
            send("Данный вид услуги здесь не предоставляется.")
            logError("doService(): unimplemented subcommand \(context.subcommand)")
            assertionFailure()
            break
        }
    }
    
    fileprivate func itemsByNameAndPrice(clerk: Creature) -> [(NameAndPrice, [Item])] {
        let itemsByNameAndPrice: [NameAndPrice: [Item]] = clerk.carrying.reduce(into: [:]) {
            (result, item) in
            let price = clerk.mobile?.shopBuyPrice(item: item) ?? 1
            let nameAndPrice = NameAndPrice(name: item.nameNominative, price: price)
            var items = result[nameAndPrice] ?? []
            items.append(item)
            result[nameAndPrice] = items
        }
        return itemsByNameAndPrice.sorted(by: { $0.key < $1.key })
    }
    
    fileprivate func isSellingItems(clerk: Creature) -> Bool {
        guard let shopkeeper = clerk.mobile?.shopkeeper,
              let _ = shopkeeper.sellProfit else { return false }
        return true;
    }
    
    fileprivate func shopGetItemByNumber(items: [(NameAndPrice, [Item])], argument: String) -> Item? {
        guard let number = Int(argument) else { return nil }
        let index = number - 1
        return items[safe: index]?.1.first
    }
    
    fileprivate func shopList(clerk: Creature, filter: String?) {
        guard isSellingItems(clerk: clerk) else {
            act("1и сказал1(,а,о,и) Вам: \"Я ничего не продаю.\"", .toCreature(self), .excludingCreature(clerk))
            return
        }
        
        guard !clerk.carrying.isEmpty else {
            act("1и сказал1(,а,о,и) Вам: \"На данный момент ничего в продаже нет.\"", .excludingCreature(clerk), .toCreature(self))
            return
        }
        
        let itemsByNameAndPrice = itemsByNameAndPrice(clerk: clerk)
        
        var output = ""
        for (index, value) in itemsByNameAndPrice.enumerated() {
            let (nameAndPrice, items) = value
            let name = nameAndPrice.name
            let price = nameAndPrice.price
            let item = items.first!
            let indexString = String(index + 1).leftExpandingTo(minimumLength: 3)
            let liquid: String
            if let vessel: ItemExtraData.Vessel = item.extraData(), !vessel.isEmpty {
                liquid = " \(vessel.liquid.instrumentalWithPreposition)"
            } else {
                liquid = ""
            }
            if index != 0 {
                output += "\n"
            }
            output += "\(indexString). \(name)\(liquid) (\(bGrn())\(price)\(nNrm()) монет\(price.ending("а", "ы", "")))"
        }
        send(output)
    }
    
    fileprivate func shopBuy(clerk: Creature, name: String) {
        guard isSellingItems(clerk: clerk), let shopkeeper = clerk.mobile?.shopkeeper else {
            act("1и сказал1(,а,о,и) Вам: \"Я ничего не продаю.\"", .toCreature(self), .excludingCreature(clerk))
            return
        }
        
        let itemsByNameAndPrice = itemsByNameAndPrice(clerk: clerk)
        let item = shopGetItemByNumber(items: itemsByNameAndPrice, argument: name)
        var itemsToSell: [Item] = []
        var createdItems: Set<Item> = []
        if let item = item {
            itemsToSell = [item]
        } else {
            var context = FetchArgumentContext(word: name, isCountable: true, isMany: true)
            let gotAllRequestedItems = clerk.fetchItemsInInventory(context: &context, into: &itemsToSell, cases: .accusative)

            if !gotAllRequestedItems {
                let itemsToProduce = min(shopSellItemsMax, context.targetAmount) - context.currentIndex + 1
                let itemToClone = itemsToSell.last { item in shopkeeper.isProducing(item: item) }
                if let itemToClone = itemToClone, let prototype = db.itemPrototypesByVnum[itemToClone.vnum] {
                    for _ in 0..<itemsToProduce {
                        let item = Item(prototype: prototype, uid: db.createUid())
                        item.give(to: clerk)
                        createdItems.insert(item)
                    }
                }
            }
        }

        let allItems = itemsToSell + createdItems
        
        guard !allItems.isEmpty else {
            act("1и сказал1(,а,о,и) Вам: \"У меня такого нет.\"",
                .excludingCreature(clerk), .toCreature(self))
            return
        }
        
        let totalPrice = allItems.reduce(0) { current, item in
            current + (clerk.mobile?.shopBuyPrice(item: item) ?? 1)
        }
        act("1и сказал1(,а,о,и) Вам: \"Это будет стоить # монет#(у,ы).\"",
            .excludingCreature(clerk), .toCreature(self), .number(totalPrice));
        
        if gold < totalPrice && !isGodMode() {
            act("1и сказал1(,а,о,и) Вам: \"У Вас не хватает денег.\"",
                .excludingCreature(clerk), .toCreature(self))
            for item in createdItems {
                item.extract(mode: .purgeAllContents)
            }
            return
        }
        
        for item in allItems {
            guard canTake(item: item, isSilent: true) else { continue }
            guard !isAlignmentMismatched(with: item) else { continue }
            
            if !shopkeeper.isProducing(item: item) || createdItems.contains(item) {
                item.removeFromCreature()
                item.give(to: self)
            } else {
                guard let prototype = db.itemPrototypesByVnum[item.vnum] else { continue }
                let clonedItem = Item(prototype: prototype, uid: db.createUid())
                clonedItem.give(to: self)
            }
            
            let price = clerk.mobile?.shopBuyPrice(item: item) ?? 1
            if !isGodMode() {
                gold -= price
            }
            clerk.gold += price
            
            act("Вы купили у 1р @1в.", .excludingCreature(clerk), .toCreature(self), .item(item))
            act("2+и купил2(,а,о,и) у 1+р @1в.", .toRoom, .excludingCreature(clerk), .excludingCreature(self), .item(item));
            
            if item.hasType(.spellbook) {
                if let decay = item.decayTimerTicsLeft, decay < 5 {
                    item.decayTimerTicsLeft = 5
                }
            }
        }
    }
}
