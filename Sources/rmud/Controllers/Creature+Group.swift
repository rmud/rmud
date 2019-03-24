import Foundation

extension Creature {
    var maximumAllowedGroupSize: Int { return 9 + Int(level) / 10 }
    
    // Was called find_new_leader findNewLeader
    func selectNewLeader(allowAnyone: Bool) -> Bool {
        let groupSize = groupedFollowersCount()
        var anyone: Creature?
        var newLeader: Creature?
        
        for follower in followers {
            if let player = follower.player, player.flags.contains(.group) &&
                    (anyone == nil || follower.level > anyone!.level) {
                anyone = follower
                if newLeader == nil || anyone!.maximumAllowedGroupSize >= groupSize {
                    newLeader = anyone
                }
            }
        }
        
        if newLeader == nil && allowAnyone {
            newLeader = anyone
        }
        
        if let newLeader = newLeader {
            // FIXME тут надо избавиться от лишних сообщений
            passLeadership(to: newLeader, isLeaving: true)
            act("Вы стали лидером группы 1р.", .toSleeping, .excludingCreature(self), .toCreature(newLeader))
            act("2*и стал2(,а,о,и) лидером группы 1*р.", .toRoom, .excludingCreature(self), .excludingCreature(newLeader))
            if newLeader.maximumAllowedGroupSize < groupSize {
                newLeader.send("Вы сомневаетесь, способны ли Вы руководить такой большой группой!")
            }
            return true
        }
        return false
    }
    
    // Note that it's 1 less than count_group_size() used to be.
    func groupedFollowersCount() -> Int {
        var count = 0
        for follower in followers {
            guard let player = follower.player else { continue }
            guard player.flags.contains(.group) else { continue }
            count += 1
        }
        return count
    }
}

