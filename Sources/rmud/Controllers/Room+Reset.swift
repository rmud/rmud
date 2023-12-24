import Foundation

extension Room {
    func reset() {
        resetFlags()
        
        resetDoors()
        
        updateExistingMobiles()
        loadMissingMobiles()
        
        purgeUntouchedItems()
        resetCoins()
        resetItems()
    }
    
    private func resetFlags() {
        flags = prototype.flags
    }
    
    private func purgeUntouchedItems() {
        for item in items {
            if item.isUntouchedByPlayers || !item.isCarryable {
                // FIXME: what if someone did put something into "untouched" item? Should try to preserve player's items
                item.extract(mode: .purgeAllContents)
            }
        }
    }
    
    private func resetDoors() {
        for direction in Direction.allDirectionsOrdered {
            guard let exit = exits[direction] else { continue }
            exit.lock = LockInfo(prototype: exit.prototype)
            exit.flags = exit.prototype.flags
            //TODO синхронизировать состояние закрытости двери, но не синхронизировать запертость!
        }
    }
    
    private func updateExistingMobiles() {
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
    }
    
    private func loadMissingMobiles() {
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
                    guard Random.probability(loadChance) else { continue }
                    let creature = Creature(prototype: prototype, uid: nil, db: db, room: self)
                    db.creaturesInGame.append(creature)
                    db.creaturesInGameByUid[creature.uid] = creature
                    creature.mobile?.homeArea = area
                    creature.mobile?.homeRoom = vnum
                    
                    // FIXME
                    //loaded_mobs.push_back(ch->uid);
                }
            }
        }
    }
        
    private func resetCoins() {
        if prototype.coinsToLoad > 0 {
            let totalCoins = totalCoinsInRoom(where: { item in
                item.isUntouchedByPlayers
            })
            if totalCoins < prototype.coinsToLoad {
                let coins = prototype.coinsToLoad - totalCoins
                if let item = Item(coins: coins) {
                    item.put(
                        in: self,
                        activateDecayTimer: false,
                        activateGroundTimer: false
                    )
                }
            }
        }
    }
    
    private func resetItems() {
        for (vnum, count) in prototype.itemsToLoadCountByVnum.sorted(by: { $0.0 < $1.0 }) {
            guard let prototype = db.itemPrototypesByVnum[vnum] else {
                logError("Reset zone: item \(vnum) does not exist")
                logToMud("Предмет \(vnum) не существует", verbosity: .complete)
                continue
            }
            
            for _ in 0 ..< count {
                guard prototype.canLoadMore() else { break }
                guard prototype.checkLoadChances() else { continue }
            
                let item = Item(prototype: prototype, uid: nil, db: db)
                guard !item.extraFlags.contains(.fragile) else {
                    logError("Reset zone: attempt to load fragile item \(vnum) into room")
                    logToMud("Попытка загрузить самоуничтожающийся предмет \(vnum) в комнату \(self.vnum)", verbosity: .complete)
                    item.extract(mode: .purgeAllContents)
                    continue
                }
                // TODO передавать ему ссылку на objs_with_trig
                item.put(in: self, activateDecayTimer: false, activateGroundTimer: false)

                item.loadContents(from: prototype)
            }
        }
    }
}
