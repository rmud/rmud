extension Creature {
    func chooseShopkeeper() -> Creature? {
        return chooseClerk(where: { creature in creature.mobile?.shopkeeper != nil })
    }
    
    private func chooseClerk(where condition: (_ creature: Creature) -> Bool) -> Creature? {
        guard let clerk = inRoom?.creatures.first(where: { creature in
            creature.isMobile && condition(creature)
        }) else {
            send("Здесь нет продавцов.")
            return nil
        }

        guard clerk.isAwake && !clerk.isHeld() else {
            act("2и сейчас не в состоянии Вас обслужить.", .to(self), .excluding(clerk))
            return nil
        }
        
        guard clerk.canSee(self) else {
            act("1и произнес1(,ла,ло,ли): \"Я не обслуживаю тех, кого не вижу!\"", .toRoom, .excluding(clerk))
            return nil
        }

        return clerk
    }
}
