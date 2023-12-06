import Foundation

extension Creature {
    func showCreature(named name: String) {
        guard !name.isEmpty else {
            send("Укажите имя персонажа или монстра.")
            return
        }

        var creatures: [Creature] = []
        var items: [Item] = []
        var room: Room?
        var string = ""
        
        let scanner = Scanner(string: name)
        guard fetchArgument(
            from: scanner,
            what: .creature,
            where: .world,
            cases: .accusative,
            condition: nil,
            intoCreatures: &creatures,
            intoItems: &items,
            intoRoom: &room,
            intoString: &string
        ) else {
            send("Персонажа с таким именем не существует.")
            return
        }

        if let creature = creatures.first {
            showStats(of: creature)
        }
    }
    
    private func showStats(of creature: Creature) {
        let uid = StatInfo("уид", creature.uid)
        if creature.isPlayer {
            sendStatGroup([
                .init("персонаж", creature.nameCompressed()),
                uid
            ], indent: 0)
        } else if let mobile = creature.mobile {
            sendStatGroup([
                .init("монстр", mobile.vnum),
                uid
            ], indent: 0)
            sendStatGroup([
                .init("имя", creature.nameCompressed()),
                .init("синонимы", mobile.synonyms.joined(separator: " "))
            ])
        }
        
        if let mobile = creature.mobile {
            var info: [StatInfo] = []
            if let homeAreaName = mobile.homeArea?.lowercasedName {
                info.append(.init("область", homeAreaName))
            }
            if let homeRoom = mobile.homeRoom {
                info.append(.init("стартовая", homeRoom))
            }
            sendStatGroup(info)
        } else if let player = creature.player {
            sendStat(.init("титул", player.customTitle))
            
            sendStatGroup([
                .init("почта", player.account.email),
                .init("адрес", player.lastIp),
                .init("хост", player.lastHostname)
            ])
            
            let createdTs = TimeInterval(player.createdAtRealWorldTime)
            let created = DateUtils.formatTimeT(createdTs)
            let logonTs = TimeInterval(player.lastLogonAtRealWorldTime)
            let logon = DateUtils.formatTimeT(logonTs)
            let (days: days, hours: hours) = player.playedTime
            
            sendStatGroup([
                .init("создан", created),
                .init("последний", logon),
                .init("играет", duration: (days: days, hours: hours))
            ])
        }
        
        if let inRoom = creature.inRoom {
            sendStat(.init("комната", inRoom.vnum))
        }
        
        if let mobile = creature.mobile {
            sendStat(.init("строка", mobile.groundDescription))
            sendStat(.init("описание", .longText(creature.description)))
        }

        sendStatGroup([
            .init("пол", Value(enumeration: creature.gender)),
            .init("раса", Value(enumeration: creature.race)),
            .init("профессия", Value(enumeration: creature.classId))
        ])

        sendStatGroup([
            .init("уровень", creature.level),
            .init("опыт", creature.experience),
            .init("наклонности", creature.realAlignment.value,
                modifier: creature.affectedAlignment().value - creature.realAlignment.value)
        ])
        
        sendStatGroup([
            .init("сила", creature.realStrength,
                  modifier: creature.affectedStrength() - Int(creature.realStrength)),
            .init("ловкость", creature.realDexterity,
                  modifier: creature.affectedDexterity() - Int(creature.realDexterity)),
            .init("телосложение", creature.realConstitution,
                  modifier: creature.affectedConstitution() - Int(creature.realConstitution)),
            .init("разум", creature.realIntelligence,
                  modifier: creature.affectedIntelligence() - Int(creature.realIntelligence)),
            .init("мудрость", creature.realWisdom,
                  modifier: creature.affectedWisdom() - Int(creature.realWisdom))
        ])
        
        if let player, level <= maximumMortalLevel {
            let gains: [(Int64, Int64?)] = player.hitPointGains.enumerated().map { (index, gain) in
                (Int64(index + 1), Int64(gain))
            }
            sendStat(.init("приросты", .dictionary(Dictionary(uniqueKeysWithValues: gains))))
        }
        
        do {
            var stats: [StatInfo] = [
                .init(
                    "жизнь", creature.hitPoints,
                    maxValue: creature.realMaximumHitPoints,
                    modifier: creature.affectedMaximumHitPoints() - creature.realMaximumHitPoints
                ),
                .init(
                    "бодрость", creature.movement,
                    maxValue: creature.realMaximumMovement,
                    modifier: creature.affectedMaximumMovement() - creature.realMaximumMovement
                ),
                .init("перевязка", creature.bandage),
                .init("наличные", creature.gold),
            ]
            if let player = creature.player {
                stats.append(.init("банк", player.bankGold))
            } else if let mobile = creature.mobile {
                stats.append(.init("перемещение", Value(enumeration: mobile.movementType)))
            }
            sendStatGroup(stats)
        }
        
        sendStatGroup([
            .init("атака", creature.realAttack,
                  modifier: creature.affectedAttack() - creature.realAttack),
            .init("защита", creature.realDefense,
                  modifier: creature.affectedDefense() - creature.realDefense),
            .init("поглощение", creature.realAbsorb,
                  modifier: creature.affectedAbsorb() - creature.realAbsorb),
            .init("допвред", creature.realDamroll,
                  modifier: creature.affectedDamroll() - Int(creature.realDamroll)),
            .init("трусость", creature.realWimpLevel,
                  modifier: creature.affectedWimpLevel() - Int(creature.realWimpLevel))
        ])

        if let mobile = creature.mobile {
            sendStat(.init("хватка", mobile.grip))
            sendStatGroup([
                .init("атак1", mobile.attacks1),
                .init("удар1", Value(enumeration: mobile.hitType1)),
                .init("вред1", Value(dice: mobile.damage1))
            ])
            if mobile.attacks2 > 0 {
                sendStatGroup([
                    .init("удар2", Value(enumeration: mobile.hitType2)),
                    .init("вред2", Value(dice: mobile.damage2)),
                    .init("атак2", mobile.attacks2)
                ])
            }
            
            let affectedSaveMagic = creature.affectedSave(.magic)
            let affectedSaveHeat = creature.affectedSave(.heat)
            let affectedSaveCold = creature.affectedSave(.cold)
            let affectedSaveAcid = creature.affectedSave(.acid)
            let affectedSaveElectricity = creature.affectedSave(.electricity)
            let affectedSaveCrush = creature.affectedSave(.crush)
            sendStatGroup([
                .init("змагия", affectedSaveMagic,
                      modifier: affectedSaveMagic - (Int(creature.realSaves[.magic] ?? 0))),
                .init("зогонь", affectedSaveHeat,
                      modifier: affectedSaveHeat - (Int(creature.realSaves[.heat] ?? 0))),
                .init("зхолод", affectedSaveCold,
                      modifier: affectedSaveCold - (Int(creature.realSaves[.cold] ?? 0))),
                .init("зкислота", affectedSaveAcid,
                      modifier: affectedSaveAcid - (Int(creature.realSaves[.acid] ?? 0))),
                .init("зэлектричество", affectedSaveElectricity,
                      modifier: affectedSaveElectricity - (Int(creature.realSaves[.electricity] ?? 0))),
                .init("зудар", affectedSaveCrush,
                      modifier: affectedSaveCrush - (Int(creature.realSaves[.crush] ?? 0))),
            ])
        }
            
        if let player = creature.player {
            sendStatGroup([
                .init("голод", creature.hunger ?? -1),
                .init("жажда", creature.thirst ?? -1),
                .init("опьянение", creature.drunk ?? -1),
                .init("простуда", player.noShoutTicsLeft),
                .init("безвыхода", player.noQuitTicsLeft),
                .init("простой", creature.idleTics)
            ])
        }
        
        sendStatGroup([
            .init("обаяние", creature.realCharisma,
                  modifier: creature.affectedCharisma() - Int(creature.realCharisma)),
            .init("вес", creature.weight),
            .init("рост", creature.height),
            .init("размер", creature.realSize,
                  modifier: creature.affectedSize() - Int(creature.realSize)),
            .init("здоровье", creature.realHealth,
                           modifier: creature.affectedHealth() - Int(creature.realHealth))
        ])

        if let player = creature.player {
            let age = GameTimeComponents(gameSeconds: player.realAgeSeconds)
            sendStatGroup([
                .init("возраст", "\(age.years)г \(age.months)м \(age.days)д \(age.hours)ч"),
                .init("лет", player.realAgeYears,
                      modifier: player.affectedAgeYears() - player.realAgeYears)
            ])
        }
        
        do {
            var stats: [StatInfo] = [
                .init("положение", Value(enumeration: creature.position))
            ]
            if let mobile = creature.mobile {
                stats += [
                    .init("начальное", Value(enumeration: mobile.defaultPosition), enumAlias: "положение"),
                    .init("предел", mobile.prototype.maximumCountInWorld ?? 0),
                    .init("исчезновение", mobile.ticsTillDisappearance ?? 0)
                ]
            } else if let player = creature.player {
                stats += [
                    .init("груз", creature.carryingWeight()),
                    .init("вход", player.loadRoom)
                ]
            }
            sendStatGroup(stats)
        }

        if let player = creature.player {
            sendStat(.init("режимы", Value(flags: player.preferenceFlags)))
            sendStat(.init("исвойства", Value(flags: player.flags)))
        } else if let mobile = creature.mobile {
            sendStat(.init("мсвойства", Value(flags: mobile.flags)))
        }

        do {
            var stats: [StatInfo] = []
            if let fighting = creature.fighting {
                stats.append(.init("противник", fighting.nameNominative.full))
            }
            if let riddenBy = creature.riddenBy {
                stats.append(.init("наездник", riddenBy.nameNominative.full))
            }
            if let riding = creature.riding {
                stats.append(.init("ездовое", riding.nameNominative.full))
            }
            if let following = creature.following {
                stats.append(.init("лидер", following.nameNominative.full))
            }
            if !creature.followers.isEmpty {
                let followers = creature.followers.map { follower in
                    follower.nameNominative.full
                }.joined(separator: ", ")
                stats.append(.init("последователи", followers))
            }
            if !stats.isEmpty {
                sendStatGroup(stats)
            }
        }
        
        // TODO: footmarks
        
        if !creature.skillLag.isEmpty {
            let lags: [(Int64, Int64?)] = creature.skillLag.map { (skill, lag) in
                (Int64(skill.rawValue), Int64(lag))
            }
            sendStat(.init("задержки", .dictionary(Dictionary(uniqueKeysWithValues: lags))))
        }
        
        if let mobile = creature.mobile {
            if let shop = mobile.shopkeeper {
                sendStatGroup([
                    .init("покупка", shop.buyProfit ?? 0),
                    .init("продажа", shop.sellProfit ?? 0),
                    .init("починка", shop.repairProfit ?? 0),
                    .init("мастерство", shop.repairLevel ?? 0),
                ])
            }
                
            if let stablemanNoteVnum = mobile.stablemanNoteVnum {
                sendStat(.init("расписка", stablemanNoteVnum))
            }
        }
        
        // TODO: affects
        
        // TODO: scripts
    }
                
    private func sendStat(_ stat: StatInfo, indent: Int = 2) {
        let indentString = String(repeating: " ", count: indent)
        send(indentString + stat.description(for: self, indent: indent))
    }
    
    private func sendStatGroup(_ stats: [StatInfo], indent: Int = 2) {
        let strings = stats.map { stat in
            stat.description(for: self, indent: indent)
        }
        let indentString = String(repeating: " ", count: indent)
        send(indentString + strings.joined(separator: " : "))
    }
}
