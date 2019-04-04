import Foundation

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
        default:
            send("Данный вид услуги здесь не предоставляется.")
            logError("doService(): unimplemented subcommand \(context.subcommand)")
            assertionFailure()
            break
        }
    }
    
    private func shopList(clerk: Creature, filter: String?) {
        guard let shopkeeper = clerk.mobile?.shopkeeper,
                let _ = shopkeeper.sellProfit else {
            act("1и сказал1(,а,о,и) Вам: \"Я ничего не продаю.\"", .toCreature(self), .excludingCreature(clerk))
            return
        }
        
        guard !clerk.carrying.isEmpty else {
            act("1и сказал1(,а,о,и) Вам: \"На данный момент ничего в продаже нет.\"", .excludingCreature(clerk), .toCreature(self))
            return
        }
        
//        var itemsByVnum: [Int: [Item]] = [:]
//        for item in clerk.carrying {
//            var items = itemsByVnum[item.vnum] ?? []
//            items.append(item)
//            itemsByVnum[item.vnum] = items
//        }
        
        let itemsByName: [String: [Item]] = clerk.carrying.reduce(into: [:]) {
            (result, item) in
            var items = result[item.nameNominative] ?? []
            items.append(item)
            result[item.nameNominative] = items
        }
        let itemsBySortedName = itemsByName.sorted(by: { $0.key < $1.key })
        
        var output = ""
        for (index, value) in itemsBySortedName.enumerated() {
            let (name, items) = value
            let item = items.first!
            let indexString = String(index + 1).leftExpandingTo(minimumLength: 3)
            let cost = clerk.mobile?.shopBuyPrice(item: item) ?? 1
            let liquid: String
            if let vessel: ItemExtraData.Vessel = item.extraData(), !vessel.isEmpty {
                liquid = " \(vessel.liquid.instrumentalWithPreposition)"
            } else {
                liquid = ""
            }
            if index != 0 {
                output += "\n"
            }
            output += "\(indexString). \(name)\(liquid) (\(bGrn())\(cost)\(nNrm()) монет\(cost.ending("а", "ы", "")))"
        }
        send(output)
    }
}
