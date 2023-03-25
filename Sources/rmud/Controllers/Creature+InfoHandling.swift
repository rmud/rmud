import Foundation

extension Creature {
    // argument - направление, куда игрок пытается смотреть
    // actual - куда реально смотрит
    func look(inDirection direction: Direction) {
        guard let inRoom = inRoom else {
            send(messages.noRoom)
            return
        }
        
        guard let exit = inRoom.exits[direction] else {
            send("\(direction.whereAtCapitalizedAndRightAligned): \(bGra())ничего особенного\(nNrm())")
            return
        }

        let toRoom = exit.toRoom()
        
        let autostat = preferenceFlags?.contains(.autostat) ?? false

        var roomVnumString = ""
        if autostat, let room = toRoom {
            roomVnumString = "[\(Format.leftPaddedVnum(room.vnum))] "
        }
        
        let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }
        
        let isMisty = toRoom?.flags.contains(.mist) ?? false
        
        var exitDescription = exit.description
        if !exitDescription.isEmpty {
            if let lastScalar = exitDescription.unicodeScalars.last,
                    !CharacterSet.punctuationCharacters.contains(lastScalar) {
                exitDescription += "."
            }
        } else if let toRoom = toRoom,
            holylight() || !exit.flags.contains(anyOf: [.hidden, .closed]) {
            if canSee(toRoom) {
                exitDescription = toRoom.name
            } else if isMisty {
                exitDescription = "ничего невозможно разглядеть."
            } else {
                exitDescription = "слишком темно."
            }
        } else {
            exitDescription = "ничего особенного."
        }
        
        send("\(direction.whereAtCapitalizedAndRightAligned): \(roomVnumString)\(bGra())\(exitDescription)\(nNrm())")
        
        if exit.type != .none {
            if (exit.flags.contains(.hidden) && exit.flags != exit.prototype.flags) ||
                    !exit.flags.contains(anyOf: [.closed, .isDoor]) {
                return
            }
            let padding = autostat ? "         " : ""
            let openClosed = exit.flags.contains(.closed) ? "закрыт" : "открыт"
            send("\(padding)            \(nCyn())\(exit.type.nominative) \(openClosed)\(exit.type.adjunctiveEnd).\(nNrm())")
        }
        
        // arilou: для самозацикленных комнат не показывать, кто там, а то это легко опознаётся
        if let toRoom = toRoom, toRoom != inRoom &&
                !exit.flags.contains(.closed) {
            if canSee(toRoom) &&
                    (!exit.flags.contains(anyOf: [.hidden, .opaque]) || holylight()) {
                send(bYel(), terminator: "")
                sendDescriptions(of: toRoom.items, withGroundDescriptionsOnly: true, bigOnly: true)
                send(bRed(), terminator: "")
                sendDescriptions(of: toRoom.creatures)
                send(nNrm(), terminator: "")
            } else if isMisty {
                var size = 0
                for creature in toRoom.creatures {
                    size += Int(creature.size)
                    if size >= 100 {
                        send("\(bGra())...Смутные тени мелькают в тумане...\(nNrm())")
                        break
                    }
                }
            }
        }
    }
    
    func lookAtRoom(ignoreBrief: Bool /* = false */) {
        guard isAwake else { return }
        
        guard !isAffected(by: .blindness) else {
            act(spells.message(.blindness, "СЛЕП"), .to(self))
            return
        }

        guard let room = inRoom else {
            send(messages.noRoom)
            return
        }
        
        let autostat = preferenceFlags?.contains(.autostat) ?? false
        if autostat {
            act("&1[&2] &3 &4<&5> &6[&7]&8",
                .to(self),
                .text(bCyn()),
                .text(String(room.vnum)),
                .text(room.name),
                .text(nGrn()),
                .text(room.terrain.name.uppercased()),
                .text(nYel()),
                .text(room.flags.description),
                .text(nNrm()))
        } else {
            act("&1&2&3",
                .to(self), .text(bCyn()), .text(room.name), .text(nNrm()))
        }
        
        let mapWidth = Int(player?.mapWidth ?? defaultMapWidth)
        let mapHeight = Int(player?.mapHeight ?? defaultMapHeight)
        
        let map: [[ColoredCharacter]]
        if preferenceFlags?.contains(.map) ?? false {
            map = player?.renderMap()?.fragment(near: room, playerRoom: room, horizontalRooms: mapWidth, verticalRooms: mapHeight) ?? []
        } else {
            map = []
        }
        let indent = "     "
        let description = indent + room.description.joined()
        let wrapped = description.wrapping(withIndent: indent, aroundTextColumn: map, totalWidth: Int(pageWidth), rightMargin: 1, bottomMargin: 0)
        
        send(wrapped.renderedAsString(withColor: true))
        
        send(bYel(), terminator: "")
        sendDescriptions(of: room.items, withGroundDescriptionsOnly: true, bigOnly: false)
        send(bRed(), terminator: "")
        sendDescriptions(of: room.creatures)
        send(nNrm(), terminator: "")
    }
    
    func look(inContainer item: Item) {
        if let container: ItemExtraData.Container = item.extraData() {
            if container.flags.contains(.closed) {
                act("@1и (&1) закрыт@1(,а,о,ы).",
                    .to(self), .item(item), .text(item.location))
            } else {
                act("Внутри @1р (&1):",
                    .to(self), .item(item), .text(item.location))
                sendDescriptions(of: item.contains,
                                 withGroundDescriptionsOnly: false,
                                 bigOnly: false)
            }
        }
        
        if let fountain: ItemExtraData.Fountain = item.extraData() {
            if fountain.isEmpty {
                act("@1и (&1) иссяк@1(,ла,ло,ли).",
                    .to(self), .item(item), .text(item.location))
            } else {
                act("Внутри @1р (&1) течет &2.",
                    .to(self), .item(item), .text(item.location),
                    .text(fountain.liquid.kind))
            }
        }
        
        if let vessel: ItemExtraData.Vessel = item.extraData() {
            if vessel.isEmpty {
                act("@1и (&1) пуст@1(,а,о,ы).",
                    .to(self), .item(item), .text(item.location))
            } else {
                let fillLevel: String
                if vessel.isFull {
                    fillLevel = "до краёв"
                } else if vessel.fillPercentage() < 50 {
                    fillLevel = "меньше чем наполовину"
                } else {
                    fillLevel = "больше чем наполовину"
                }
                act("@1и (&1) заполнен@1(,а,о,ы) &2 &3.",
                    .to(self), .item(item), .text(item.location),
                    .text(vessel.liquid.instrumental),
                    .text(fillLevel))
            }
        }
    }
    
    func look(atReceipt item: Item) {
        
    }
    
    func sendDescriptions(of items: [Item], withGroundDescriptionsOnly: Bool, bigOnly: Bool) {
        let shouldStack = preferenceFlags?.contains(.stackItems) ?? false
        var stackedItemsCount = 0
        var lastItem: Item?
        var lastItemDescription = ""
        
        let showLastDescriptionIfAny = {
            guard stackedItemsCount > 0 else { return } // nothing to show
            if stackedItemsCount > 1 {
                self.send("\(lastItemDescription) [\(stackedItemsCount)]")
            } else {
                self.send(lastItemDescription)
            }
        }
        defer { showLastDescriptionIfAny() }
        
        for item in items {
            guard !bigOnly || item.extraFlags.contains(.big) else { continue }
            guard !withGroundDescriptionsOnly || !item.groundDescription.isEmpty else { continue }
            guard canSee(item) else { continue }
            
            let description = describe(item: item)
            
            guard shouldStack else {
                send(description)
                continue
            }
            
            if stackedItemsCount > 0,
                    let lastItem = lastItem,
                    item.vnum == lastItem.vnum &&
                        description == lastItemDescription {
                stackedItemsCount += 1
            } else {
                showLastDescriptionIfAny()
                lastItem = item
                lastItemDescription = description
                stackedItemsCount = 1
            }
        }
    }
    
    // Lists chars in room, with char stacking routine
    func sendDescriptions(of people: [Creature]) {
        let shouldShow: (_ creature: Creature)->Bool = { creature in
            let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }
            let canSeeCreatureAndItsNotHiding: (_ creature: Creature)->Bool = { creature in
                self.canSee(creature) &&
                (!creature.runtimeFlags.contains(.hiding) || self.isAffected(by: .senseLife) || holylight()) }
            let creatureIsRidingAndCanSeeWhomItsRiding: (_ creature: Creature)->Bool = { creature in
                if let riding = creature.riding, self.canSee(riding) {
                    return true
                }
                return false
            }
            let isRiddenBySomeoneExceptMe: (_ creature: Creature)->Bool = { creature in
                if let creatureRiddenBy = creature.riddenBy,
                        creatureRiddenBy.inRoom == creature.inRoom,
                        creatureRiddenBy != self {
                    return true
                }
                return false
            }
            return (
                canSeeCreatureAndItsNotHiding(creature) ||
                self.riding == creature ||
                creature.hasDetectableItems() ||
                creatureIsRidingAndCanSeeWhomItsRiding(creature)
            ) && !isRiddenBySomeoneExceptMe(creature)
        }
        
        let shouldStack = preferenceFlags?.contains(.stackMobiles) ?? false
        var stackedCreaturesCount = 0
        var lastCreature: Creature?
        var lastCreatureDescription = ""

        let showLastDescriptionIfAny = {
            guard stackedCreaturesCount > 0 else { return } // nothing to show
            if stackedCreaturesCount > 1 {
                self.send("\(lastCreatureDescription) [\(stackedCreaturesCount)]")
            } else {
                self.send(lastCreatureDescription)
            }
        }
        defer { showLastDescriptionIfAny() }

        for creature in people {
            guard self != creature && shouldShow(creature) else { continue }

            let creatureMirrorImagesCount = creature.isAffected(by: .mirrorImage) ? creature.mirrorImagesCount() : 0
            
            let description = describe(creature: creature)
            
            guard shouldStack else {
                for _ in 0..<(1 + creatureMirrorImagesCount) {
                    send(description)
                }
                continue
            }

            if stackedCreaturesCount > 0,
                    let lastCreature = lastCreature,
                    let creatureMobile = creature.mobile,
                    let lastCreatureMobile = lastCreature.mobile,
                    creatureMobile.vnum == lastCreatureMobile.vnum &&
                    description == lastCreatureDescription {
                stackedCreaturesCount += (1 + creatureMirrorImagesCount)
            } else {
                showLastDescriptionIfAny()
                lastCreature = creature
                lastCreatureDescription = description
                stackedCreaturesCount = 1 + creatureMirrorImagesCount
            }
        }
    }
    
    func sendPoofIn() {
        if let player = player,
            !player.poofin.isEmpty,
            let room = inRoom {
            for to in room.creatures {
                guard to != self && to.canSee(self) else { continue }
                to.send(player.poofin)
            }
        } else {
            act("1*и появил1(ся,ась,ось,ись) в клубах дыма.", .toRoom, .excluding(self))
        }
    }
    
    func sendPoofOut() {
        if let player = player,
                !player.poofout.isEmpty,
                let room = inRoom {
            for to in room.creatures {
                guard to != self && to.canSee(self) else { continue }
                to.send(player.poofout)
            }
        } else {
            act("1*и исчез1(,ла,ло,ли) в клубах дыма.", .toRoom, .excluding(self))
        }
    }
}
