import Foundation

extension Creature {
    func doInventory(context: CommandContext) {
        guard !carrying.isEmpty else {
            send("У Вас в руках ничего нет.")
            return
        }
        send("У Вас в руках:")
        sendDescriptions(of: carrying, withGroundDescriptionsOnly: false, bigOnly: false)
    }
    
    func doDrop(context: CommandContext) {
        guard !context.items1.isEmpty else {
            send("Что Вы хотите выбросить?")
            return
        }
        for item in context.items1 {
            performDrop(item: item)
        }
    }
    
    private func performDrop(item: Item) {
        guard let inRoom = inRoom else {
            assertionFailure()
            return
        }
        
//        if (!drop_otrigger(obj, ch) || !drop_wtrigger(obj, ch))
//        return;
        
        let toActorDefaultMessage = { (isAllowed: Bool) -> String in
            return isAllowed ? "Вы выбросили @1в." : "Вы не смогли выбросить @1в."
        }
        
        let toRoomDefaultMessage = { (isAllowed: Bool) -> String in
            return isAllowed ?
                "1*и выбросил1(,а,о,и) @1в." :
                "1*и попытал1(ся,ась,ось,ись) выбросить @1в, но не смог(,ла,ло,ли)."
        }

        let event = item.override(eventId: .drop)
        let toActor = event.toActor ?? toActorDefaultMessage(event.isAllowed)
        let toRoom = event.toRoomExcludingActor ??
            toRoomDefaultMessage(event.isAllowed)
        act(toActor, .toCreature(self), .item(item))
        act(toRoom, .toRoom, .excludingCreature(self), .item(item))
        guard event.isAllowed else { return }

        if level > Level.hero && level < Level.implementor {
            logIntervention("\(nameNominative) бросает \(item.nameAccusative) в комнате \"\(inRoom.name)\".")
        }
        
        if inRoom.flags.contains(.dump) && !item.extraFlags.contains(.fragile) {
            act("@1и упал@1(,а,о,и) в кучу мусора.", .toRoom, .toCreature(self), .item(item))
            /*    if (!OBJ_FLAGGED(obj, ITEM_STINK)) {
             int exp = obj->cond_max ? (obj->cost * obj->cond_current) / obj->cond_max : 0;
             if (exp > 0) gain_exp(ch, exp, GAIN_EXP_NORMAL);
             } */
            item.extraFlags.insert(.stink)
            item.extraFlags.insert(.buried)
        }
        
        if item.vnum == vnumSpellDelayedBlastFireball { // fiery crystall spec. case
            lagAdd(pulseViolence / 2)
            /*  spell_dbf_wand_miscast(ch, obj, false);
             call_magic(ch, ch, obj, SPELL_FIREBALL, OBJ_VAL(obj, 0), CAST_WAND, NULL);
             return; */
        }
        
        item.removeFromCreature()
        item.put(in: inRoom, activateDecayTimer: true)

        if !item.wearFlags.contains(.take) {
            item.groundTimerTicsLeft = 0
        }
        player?.scheduleForSaving() // to prevent item and cash cloning
    }
}
