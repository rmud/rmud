import Foundation

extension Mobile {
    func mobileActivity() {
        moveAlongPath()
    }
    
    func checkForTargets() {
//        guard creature.position == .standing || creature.position == defaultPosition else { return }
//
//        // aggressive mobs
//        if !flags.isDisjoint(with: MobileFlags.allMobAgro.union(.xenophobiac)) &&
//                !flags.contains(.agroSlow) { //  !(room->flagged(ROOM_PEACEFUL) && MOB_TIMER(ch)))
//            var foundCount = 0
//            var victim: Creature?
//            for tmp in creature.inRoom.people {
//                if (tmp.isMobile && !tmp.mobile!.flags.contains(.xenophobiac)) ||
//                        creature == tmp || !creature.canSee(tmp) ||
//                        (tmp.isPlayer && tmp.preferenceFlags.contains(.nohassle)) {
//                    continue
//                }
//                if tmp.runtimeFlags.contains(.hiding) && !creature.isAffected(by: .senseLife) {
//                    continue
//                }
//                if creature->mob_aggr_vict(tmp) && can_attack(ch, tmp) {
//                    foundCount += 1
//                    if Random.uniformInt(1...foundCount) == 1 {
//                        victim = tmp
//                    }
//                }
//            }
//            if let victim = victim {
//                creature.mob_attack(victim: victim)
//                return
//            }
//        }
    
//        creature.mob_revenge_check(ch)
    }
    
    private func moveAlongPath() {
        guard !pathName.isEmpty else { return }
        guard let room = creature.inRoom else { return }
        guard let path = room.area?.prototype.paths[pathName] else { return }
        let possibleDirections = Direction.allDirections.filter { direction in
            guard let exit = room.exits[direction] else { return false }
            guard let toVnum = exit.toVnum else { return false }
            guard path.contains(toVnum) else { return false }
            guard let toRoom = db.roomsByVnum[toVnum] else { return false }
            guard toRoom.area == room.area else { return false }
            return true
        }
        guard let direction = possibleDirections.randomElement() else { return }
        let _ = creature.performMove(direction: direction, mode: .normal)
    }
}
