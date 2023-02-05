import Foundation

extension Creature {
    func isGodMode() -> Bool {
        return preferenceFlags?.contains(.godMode) ?? false
    }
    
    func isHeld() -> Bool {
        return isAffected(by: .hold) && !isAffected(by: .freeAction)
    }
    
    func isFlying() -> Bool {
        return isAffected(by: .fly)
    }
    
    func isCharmed() -> Bool {
        return isAffected(by: .charm)
    }
    
    func hasLitOrGlowingItems() -> Bool {
        return isCarryingOrWearingItem(where: { item in
            if item.extraFlags.contains(anyOf: .glow) {
                return true
            }
            if item.isWorn,
                let light: ItemExtraData.Light = item.extraData(),
                light.ticsLeft > 0 {
                return true
            }
            return false
        })
    }
    
    func hasDetectableItems() -> Bool {
        if hasLitOrGlowingItems() {
            return true
        }
        return isCarryingOrWearingItem(withAnyOf: [.hum, .stink, .fragrant])
    }
    
    func hasPlayerMaster() -> Bool {
        var creature = self
        while let master = creature.following {
            if master.isPlayer { return true }
            creature = master
        }
        return false
    }

    var isLagged: Bool { return lagRemain > 0 }

    func lagSet(_ lagLength: Int) {
        guard lagLength > 0 && !isGodMode() else { return }
        laggedTillGamePulse = max(gameTime.gamePulse + UInt64(lagLength), laggedTillGamePulse)
    }
    
    func lagAdd(_ lagInc: Int) {
        guard lagInc > 0 && !isGodMode() else { return }
        laggedTillGamePulse = (laggedTillGamePulse > gameTime.gamePulse ?
            laggedTillGamePulse : gameTime.gamePulse) + UInt64(lagInc)
    }
    
    var lagRemain: Int {
        if gameTime.gamePulse > laggedTillGamePulse {
            return Int(gameTime.gamePulse - laggedTillGamePulse)
        }
        return 0
    }
    
    func canGo(_ direction: Direction) -> Bool {
        guard let ex = inRoom?.exits[direction] else { return false }
        guard nil != ex.toRoom() else { return false }
        guard !ex.flags.contains(.closed) && !ex.flags.contains(.barOut) else { return false }
        return true
    }

    func willFallHere() -> Bool {
        guard let inRoom = inRoom else { return false }
        return inRoom.terrain == .air && canGo(.down) &&
            !isAffected(by: .fly) &&
            (!isRiding || !riding!.isAffected(by: .fly))
    }
    
    // FIXME: overrides which cancel action should probably be prioritized
    func override(eventIds: MobileEventId...) -> Event<MobileEventId> {
        let chosenId: MobileEventId
        if eventIds.isEmpty {
            assertionFailure()
            chosenId = .invalid
        } else {
            chosenId = .invalid // FIXME
        }
        //        for override in actionOverrides {
        //            if override.action == action {
        //                return override
        //            }
        //        }
        return Event<MobileEventId>(eventId: chosenId)
    }
    
    func override(eventId: MobileEventId) -> Event<MobileEventId> {
        return override(eventIds: eventId)
    }

    func canSee(_ room: Room) -> Bool {
        return true // FIXME
    }

    func canSee(_ whom: Creature) -> Bool {
        return true // FIXME
    }
    
    func canSee(_ item: Item) -> Bool {
        return true // FIXME
    }
    
    

    // Simple function to determine if a non-flying char can walk on water
    func hasBoat() -> Bool {
        // Boats in inventory will do it
        for item in carrying {
            // item.type == .boat {
            if item.hasType(.boat) {
                return true
            }
        }
        
        // And any boat you're wearing will do it too
        for (_, item) in equipment {
            if item.hasType(.boat) {
                return true
            }
        }
    
        return false
    }
}
