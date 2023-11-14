import Foundation

extension Mobile {
    func updateOnReset() {
        if homeRoom == nil { // && !has_trig
            // Delete mobile, drop items to the ground
            creature.extract(mode: .leaveItemsOnGround)
            return
        }
        
        // поднимаем монстров, которые были в минусах
        if creature.hitPoints < 1 && creature.hitPoints < creature.affectedMaximumHitPoints() {
            creature.hitPoints = 1
            creature.updatePosition()
        }
        let _ = returnHome() // error already reported in returnHome()
        if isShopkeeper {
            updateShopOnReset()
        }
        reequip()
    }
    
    private func returnHome() -> Bool {
        guard flags.contains(.returning) else { return false }
        guard let homeRoom = homeRoom else {
            logError("returnHome(): returning mobile \(vnum) has no start room and wasn't deleted (has reset-trigger?)")
            return false
        }
        guard let room = db.roomsByVnum[homeRoom] else {
            logError("returnHome(): returning mobile \(vnum)'s homeroom \(homeRoom) does not exist")
            return false
        }
        creature.teleportTo(room: room)
        return true
    }
    
    private func reequip() {
        // убрать весь шмот, который в нём лоадится и снять весь остальной шмот
        for item in creature.carrying {
            if !item.isDecayTimerEnabled {
                item.unloadNativeItem()
            }
        }

        for (position, item) in creature.equipment {
            // проверки таймера достаточно, только у своих предметов он выключен
            if !item.isDecayTimerEnabled {
                item.unloadNativeItem()
            } else {
                // позиция может понадобиться для лоада своего шмота
                let item = creature.unequip(position: position)
                item?.give(to: creature)
            }
                
        }
        // TODO когда научится использовать чужие предметы: составить список чужого шмота
        // list<obj_data*> old_items = mob->carrying;
        
        // снарядить заново
        equip()
        
        // TODO когда научится использовать чужие предметы:
        // если было что-то посторонне - заново пробовать надеть
    }
    
    func equip() {
        loadEquipmentAndInventory()
        // Load producing objects for shopkeepers:
        shopLoadMenu()
    }
    
    private func loadEquipmentAndInventory() {
        let tryLoadItem: (_ vnum: Int) -> Item? = { vnum in
            guard let itemPrototype = db.itemPrototypesByVnum[vnum] else {
                logError("Attempt to load non-existent item \(vnum)")
                return nil
            }

            guard itemPrototype.checkMaximumAndLoadChances() else { return nil }

            let item = Item(prototype: itemPrototype, uid: db.createUid() /*, in: self.homeArea */)

            //obj = read_object(*obj);
            // FIXME: load contents in Item's constructor
            //if (obj->contents) obj_load_contents(obj);
            
            return item
        }
        
        let performPostloadActions: (_ item: Item) -> () = { item in
            // Items shouldn't decay on mobiles unless given by players
            item.setDecayTimerRecursively(activate: false)
            // FIXME
            //obj_enlist_postload(obj);
        }
        
        for (vnum, equipWhere) in prototype.loadEquipmentWhereByVnum {
            // Если загрузка на фиксированное место - проверяем, свободно ли оно
            // сообщение не выдаём, так как может быть преднамеренная загрузка двух
            // предметов в один слот
            if case .equip(let position) = equipWhere,
                    creature.equipment[position] != nil {
                continue
            }

            guard let item = tryLoadItem(vnum) else { continue }
            
            switch equipWhere {
            case .equip(let position):
                creature.equip(item: item, position: position)
            case .equipAnywhere:
                creature.wear(item: item, isSilent: true)
                if !item.isWornBySomeone {
                    if !tryWearing(item: item, ifHasFlags: .wield, at: [.wield]) {
                        if !tryWearing(item: item, ifHasFlags: .hold, at: [.hold]) {
                            if !tryWearing(item: item, ifHasFlags: .twoHand, at: [.twoHand]) {
                                logError("Unable to equip mobile \(self.vnum) with item \(vnum) on load")
                                item.extract(mode: .purgeAllContents)
                                continue
                            }
                        }
                    }
                }
            }
            
            performPostloadActions(item)
        }
        
        for (vnum, count) in prototype.loadInventoryCountByVnum {
            guard count > 0 else {
                logError("Mobile \(vnum): item \(vnum) has invalid load count: \(count)")
                continue
            }
            for _ in 0..<count {
                guard let item = tryLoadItem(vnum) else { continue }
                item.give(to: creature)
                performPostloadActions(item)
            }
        }

    }
    
    private func tryWearing(item: Item, ifHasFlags flags: ItemWearFlags, at positions: [EquipmentPosition]) -> Bool {
        if item.wearFlags.contains(anyOf: flags) {
            creature.performWear(item: item, positions: positions, isSilent: true)
        }
        return item.isWornBySomeone
    }
}
