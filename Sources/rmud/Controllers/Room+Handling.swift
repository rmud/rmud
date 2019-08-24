import Foundation

extension Room {
    func reset() {
        // Восстанавливаем флаги
        flags = prototype.flags

        // Reload items that remain untouched. First, purge them:
        for item in items {
            if (!item.isDecayTimerEnabled && !item.isGroundTimerEnabled) ||
                    !item.wearFlags.contains(.take) {
                // FIXME: what if someone did put something into "untouched" item? Should try to preserve player's items
                item.extract(mode: .purgeAllContents)
            }
        }

        // Reset doors:
        for direction in Direction.orderedDirections {
            guard let exit = exits[direction] else { continue }
            exit.lock = LockInfo(prototype: exit.prototype)
            exit.flags = exit.prototype.flags
            //TODO синхронизировать состояние закрытости двери, но не синхронизировать запертость!
        }

        // Update already existing mobiles:
        for creature in creatures {
            guard let mobile = creature.mobile else { continue }
            if mobile.homeArea == area &&
                    !(creature.isFighting ||
                      creature.hasPlayerMaster() ||
                      mobile.willDisappearEventually) {
                // TODO передавать ему ссылку на objs_with_trig
                mobile.updateOnReset()
            }
        }

        // Reset mobiles
        for (vnum, count) in prototype.mobilesToLoadCountByVnum.sorted(by: { $0.0 < $1.0 }) {
            let existingMobilesCount = creatures.count(
                where: { $0.isMobile && $0.mobile!.vnum == vnum })
            let toLoadCount = count - existingMobilesCount
            if toLoadCount > 0 {
                for _ in 0 ..< toLoadCount {
                    //guard let prototype = area?.prototype.mobilesById[loadInfo.vnum] else {
                    guard let prototype = db.mobilePrototypesByVnum[vnum] else {
                        logWarning("Mobile prototype \(vnum) not found on reset")
                        continue
                    }
                    let countInWorld = db.mobilesCountByVnum[vnum] ?? 0
                    
                    if let loadMaximum = prototype.maximumCountInWorld,
                            countInWorld >= loadMaximum {
                        break
                    }
                    let loadChance = prototype.loadChancePercentage ?? 100
                    guard Random.uniformInt(1...100) <= loadChance else { continue }
                    guard let creature = Creature(prototype: prototype, uid: db.createUid(), room: self) else {
                        logWarning("Unable to instantiate mobile \(vnum) from prototype")
                        continue
                    }
                    db.creaturesInGame.append(creature)
                    creature.mobile?.homeArea = area
                    creature.mobile?.homeRoom = vnum
                    
                    // FIXME
                    //loaded_mobs.push_back(ch->uid);
                }
            }
        }
    }
}
