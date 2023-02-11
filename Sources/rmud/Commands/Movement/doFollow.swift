extension Creature {
    func doFollow(context: CommandContext) {
        guard let creature = context.creature1 else {
            if let following = following {
                act("Вы следуете за 2т.", .toSleeping,
                    .to(self), .excluding(following))
            } else {
                send("Вы ни за кем не следуете.")
            }
            return
        }
        
        guard following != creature else {
            act("Вы уже следуете за 2т.", .toSleeping,
                .to(self), .excluding(creature))
            return
        }
        
        //guard !isCharmed() else {
        //    act("Вы хотите следовать только за 2т!", .toSleeping,
        //        .to(self), .excluding(following))
        //    return
        //}

        if creature == self {
            if !isFollowing {
                send("Вы уже ни за кем не следуете.")
            } else {
                stopFollowing()
            }
        } else {
            if isFollowing {
                stopFollowing()
            }
            follow(leader: creature, silent: false)
        }
    }
}
