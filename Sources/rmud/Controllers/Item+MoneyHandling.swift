import Foundation

extension Item {
    func updateMoneyNameAndDescription() {
        guard let money = asMoney() else { return }
        let amount = money.amount

        let names = moneyNames(amount: amount)
        setNames(names, isAnimate: false)
        description = [moneyDescription(amount: amount)]
        groundDescription = moneyGroundDescription(amount: amount)
    }

    private func moneyNames(amount: Int) -> String {
        if (amount < 1) {
            return "ГЛЮК"
        } else if (amount == 1) {
            return "стальн(ая) монет(а)"
        } else if (amount <= 5) {
            return "горсточ(ка) стальных монет";
        } else if (amount <= 10) {
            return "маленьк(ая) куч(ка) стальных монет"
        } else if (amount <= 25) {
            return "небольш(ая) куч(ка) стальных монет"
        } else if (amount <= 50) {
            return "куч(ка) стальных монет"
        } else if (amount <= 100) {
            return "ку(ча) стальных монет"
        } else if (amount <= 250) {
            return "больш(ая) ку(ча) стальных монет"
        } else if (amount <= 500) {
            return "огромн(ая) ку(ча) стальных монет"
        } else if (amount <= 1000) {
            return "груд(а) стальных монет"
        }
        return "гор(а) стальных монет"
    }
    
    private func moneyDescription(amount: Int) -> String {
        if amount < 1 {
            return "ГЛЮК"
        } else if amount == 1 {
            return "Это одна обычная стальная монета."
        } else if amount < 10 {
            return "Здесь \(amount) монет."
        } else if amount < 100 {
            let approximate = (amount / 10) * 10
            return "Здесь примерно \(approximate) монет."
        } else if amount < 1000 {
            let approximate = (amount / 100) * 100
            return "Похоже, что здесь примерно \(approximate) монет."
        } else if amount < 100000 {
            let approximate = (amount / 1000 + Int.random(in: 0...amount / 1000)) * 1000
            return "Вы предполагаете, что здесь около \(approximate) монет."
        }
        return "Здесь очень много монет."
    }
    
    private func moneyGroundDescription(amount: Int) -> String {
        if amount < 1 {
            return "(ГЛЮК)"
        } else if amount == 1 {
            return "Одна стальная монета лежит здесь."
        }
        return "\(nameNominative.full.capitalizingFirstLetter()) лежит здесь."
    }
}
