
extension Creature {
    func doList(context: CommandContext) {
        guard let shopkeeper = chooseShopkeeper() else { return }
        
        shopList(clerk: shopkeeper, filter: context.argument1)
    }
    
    private func shopList(clerk: Creature, filter: String?) {
        guard clerk.isSellingItems else {
            act("1и сказал1(,а,о,и) Вам: \"Я ничего не продаю.\"", .to(self), .excluding(clerk))
            return
        }
        
        guard !clerk.carrying.isEmpty else {
            act("1и сказал1(,а,о,и) Вам: \"На данный момент ничего в продаже нет.\"", .excluding(clerk), .to(self))
            return
        }
        
        let itemsByNameAndPrice = clerk.shopItemsByNameAndPrice()
        
        var output = ""
        for (index, value) in itemsByNameAndPrice.enumerated() {
            let (nameAndPrice, items) = value
            let name = nameAndPrice.name
            let price = nameAndPrice.price
            let item = items.first!
            let indexString = String(index + 1).leftExpandingTo(3)
            let liquid: String
            if let vessel = item.asVessel(), !vessel.isEmpty {
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
}
