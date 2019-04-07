import Foundation

extension Creature {
    func notImplemented(context: CommandContext) {
        send("Эта команда всё ещё не реализована.")
    }
}

extension Creature {
    func doMap(context: CommandContext) {
        guard let room = inRoom,
                let area = room.area,
                let renderedMap = area.renderedMap else {
            send("Карта этой области отсутствует.")
            return
        }

        let sendMap: (_ map: String)->() = { map in
            guard !map.isEmpty else {
                self.send("На этом уровне карта отсутствует.")
                return
            }
            self.send(map)
        }
        
        let what = context.argument1
        if what.isEqual(toOneOf: ["вся", "все", "all"], caseInsensitive: true) {
            let planes = renderedMap.planes.sorted(by: >)
            for plane in planes {
                send("Уровень \(plane):")
                let map = renderedMap.fragment(wholePlane: plane, playerRoom: room)
                sendMap(map.renderedAsString(withColor: true))
            }
            return
        }
        
        if let plane = Int(what) {
            send("Уровень \(plane):")
            let map = renderedMap.fragment(wholePlane: plane, playerRoom: room)
            sendMap(map.renderedAsString(withColor: true))
            return
        }

        if let plane = renderedMap.plane(forRoom: room) {
            let map = renderedMap.fragment(wholePlane: plane, playerRoom: room)
            sendMap(map.renderedAsString(withColor: true))
            return
        }

        log("Room \(room.vnum) not found on map.")
        logToMud("Комната \(room.vnum) не найдена на карте.", verbosity: .brief, minLevel: Level.lesserGod)
    }
}

extension Creature {
    func doWho(context: CommandContext) {
        var showImmortals = false
        var showMortals = false
        var showTitledOnly = false
        var namesToSearchLowercased: [String] = []
        
        while let word = context.scanWord(ignoringFillWords: false) {
            switch word.lowercased() {
            case "боги": showImmortals = true
            case "смертные": showMortals = true
            case "титулованные": showTitledOnly = true
            default: namesToSearchLowercased.append(word)
            }
        }
        if !showImmortals && !showMortals {
            // If neither were specified, show both
            showImmortals = true
            showMortals = true
        }
        
        let holylight = preferenceFlags?.contains(.holylight) ?? false
        
        let whoList: [Player] = networking.descriptors.filter { descriptor in
            guard descriptor.state == .playing else { return false }

            let target: Creature
            if let original = descriptor.original {
                target = original
            } else if let creature = descriptor.creature {
                target = creature
            } else {
                return false
            }

            guard let targetPlayer = target.player else { return false }
            guard !targetPlayer.isMortalAndLinkDead || holylight else { return false }
            guard canSee(target) else { return false }
            
            if target.level >= Level.hero {
                guard showImmortals else { return false }
            } else {
                guard showMortals else { return false }
            }

            return true
        }.compactMap { descriptor in
            return descriptor.original ?? descriptor.creature
        }.sorted { lhs, rhs in
            if lhs.level >= Level.hero {
                return rhs.level < Level.hero || lhs.level > rhs.level || (lhs.level == rhs.level && lhs.nameNominative < rhs.nameNominative)
            } else {
                return rhs.level < Level.hero && lhs.nameNominative < rhs.nameNominative
            }
        }.compactMap { creature in
            return creature.player
        }
        
        var immortalsCount = 0
        var mortalsCount = 0
        var output = ""
        for targetPlayer in whoList {
            let targetCreature = targetPlayer.creature
            
            guard !showTitledOnly || !targetPlayer.customTitle.isEmpty else {
                continue
            }
            if !namesToSearchLowercased.isEmpty {
                let nameLowercased = targetCreature.nameNominative.lowercased()
                var matches = true
                for searchString in namesToSearchLowercased {
                    guard nameLowercased.contains(searchString) else {
                        matches = false
                        break
                    }
                }
                guard matches else { continue }
            }
            
            let prefix: String
            
            let autostatPrefix: ()->String = {
                let levelString = String(targetCreature.level).leftExpandingTo(minimumLength: 2, with: "0")
                let classAbbreviation = targetCreature.classId.info.abbreviation.leftExpandingTo(minimumLength: 3)
                return "[\(levelString) \(classAbbreviation)]"
            }
            
            let isImmortal = targetCreature.level >= Level.hero
            if isImmortal {
                immortalsCount += 1
                if immortalsCount == 1 {
                    output +=
                        "\(nCyn())Бессмертные\n" +
                                 "-----------\(nNrm())\n"
                }
                if targetPlayer.preferenceFlags.contains(.autostat) {
                    prefix = autostatPrefix()
                } else {
                    prefix = Level.whoLevelPrefix(level: targetCreature.level, gender: targetCreature.gender)
                }
            } else {
                mortalsCount += 1
                if mortalsCount == 1 {
                    if immortalsCount > 0 {
                        output += "\r\n"
                    }
                    output +=
                        "\(nCyn())Смертные\n" +
                                 "--------\(nNrm())\n"
                }
                if targetPlayer.preferenceFlags.contains(.autostat) {
                    prefix = autostatPrefix()
                } else {
                    prefix = ""
                }
            }
            
            var format = "&1&2&3" // color on, prefix, title
            if holylight && targetPlayer.adminInvisibilityLevel > 0 {
                format.append(" (н#1)")
            }
            if targetPlayer.flags.contains(anyOf: [.mailing, .writing]) {
                format.append(" (пиш2(е,е,е,у)т)")
            }

            if targetPlayer.preferenceFlags.contains(.deaf) {
                format.append(" (глух2(,а,о,и))")
            }
            
            if targetPlayer.preferenceFlags.contains(.busy) {
                format.append(" (занят2(,а,о,ы))")
            }
            format.append("&4") // color off

            let titleToShow = targetPlayer.titleWithFallbackToRace(order: .nameThenRace)
            let flags: ActFlags = .toSleeping
            let args: [ActArgument] = [
                .toCreature(self),
                .excludingCreature(targetCreature),
                .number(Int(targetPlayer.adminInvisibilityLevel)), // #1
                .text(isImmortal ? bWht() : bCyn()), // &1
                .text(!prefix.isEmpty ? prefix.appending(" ") : ""), // &2
                .text(titleToShow), // &3
                .text(nNrm()) // &4
            ]
            act(format, flags, args) { target, actOutput in
                output.append(actOutput)
                output.append("\n")
            }
        }

        if immortalsCount == 0 && mortalsCount == 0 {
            if !namesToSearchLowercased.isEmpty {
                send("Персонажей с такими именами в игре нет.")
            } else {
                send("Никого нет.")
            }
        } else {
            var format = "\n&1" // &1 for color on
            if immortalsCount > 0 {
                format.append("#1 бессмертн#1(ый,ых,ых)")
            }
            if immortalsCount > 0 && mortalsCount > 0 {
                format.append(" и ")
            }
            if mortalsCount > 0 {
                format.append("#2 смертн#2(ый,ых,ых)")
            }
            format.append(".&2") // color off
            
            act(format,
                .toSleeping,
                .toCreature(self),
                .number(immortalsCount), // #1
                .number(mortalsCount), // #2
                .text(nCyn()), // &1
                .text(nNrm()) // &2
            ) { target, actOutput in
                output += actOutput
            }
            
            // FIXME
            //page_string(ch->desc, buf, true);
            send(output)
            
            // FIXME: why here?
            let playersCount = immortalsCount + mortalsCount
            if playersCount > networking.topPlayersCountSinceBoot {
                networking.topPlayersCountSinceBoot = playersCount
                //log("Top players count since boot: \(playersCount)")
                logToMud("Игра достигла пиковой нагрузки: \(playersCount) персонаж\(playersCount.ending("", "а", "ей"))", verbosity: .normal, minLevel: Level.lesserGod)
            }
        }
    }
}

extension Creature {
    func doScore(context: CommandContext) {
        let raceName = race.info.namesByGender[gender] ?? "(раса неизвестна)"
        
        let className = classId.info.namesByGender[gender] ?? "(профессия неизвестна)"

        if let player = player {
            do {
                let affectedAgeComponents = GameTimeComponents(gameSeconds: player.affectedAgeSeconds())
                act("Вы &1 1и, &2 #1 уровня. Вам #2 #2(год,года,лет).", .toSleeping,
                    .toCreature(self), .text(raceName), .text(className), .number(Int(level)), .number(affectedAgeComponents.years))
            }
            
            do {
                let realAgeComponents = GameTimeComponents(gameSeconds: player.realAgeSeconds)
                if realAgeComponents.months == 0 && realAgeComponents.days == 0 {
                    send("У Вас сегодня день рождения.")
                }
            }
        } else {
            act("Вы &1 1и, &2 #1 уровня.", .toSleeping,
                .toCreature(self), .text(raceName), .text(className), .number(Int(level)))
        }
        
        if context.argument1.isAbbreviation(ofOneOf: ["склонение", "declension"], caseInsensitive: true) {
            act("Склонение Вашего имени: 1и/1р/1д/1в/1т/1п.", .toSleeping, .toCreature(self))
        }
        
        if let player = player {
            if !player.customTitle.isEmpty {
                send("Вы носите титул \"\(player.customTitle)\".")
            }
            if !player.titleRequest.isEmpty {
                send("Вы запросили титул \"\(player.titleRequest)\".")
            }
        }
        
        act("У Вас сейчас #1 из #2 очк#1(о,а,ов) жизни и #3 из #4 очк#3(о,а,ов) бодрости.",
            .toSleeping, .toCreature(self), .number(hitPoints), .number(affectedMaximumHitPoints()), .number(movement), .number(affectedMaximumMovement()))
        
        let alignment = affectedAlignment()
        let alignmentCategory = alignment.category
        send(alignment.category.description)
        
        if classId.info.classGroup == .wizard  {
            switch alignmentCategory {
            case .veryGood, .moderatelyGood, .slightlyGood:
                send("Вам покровительствует белая луна, Солинари.")
            case .barelyGood:
                send("Вам пока еще покровительствует белая луна, Солинари.")
            case .neutralBorderingGood, .neutralBorderingEvil:
                send("Вам пока еще покровительствует красная луна, Лунитари.")
            case .neutral:
                send("Вам покровительствует красная луна, Лунитари.")
            case .barelyEvil:
                send("Вам пока еще покровительствует черная луна, Нуитари.")
            case .slightlyEvil, .moderatelyEvil, .veryEvil:
                send("Вам покровительствует черная луна, Нуитари.")
            }
        }

        if isPlayer && level < Level.hero {
            var format = "Вы набрали #1 очк#1(о,а,ов) опыта."
            let experienceNeeded = classId.info.experience(forLevel: level + 1) - experience
            if experienceNeeded > 0 {
                format += " До следующего уровня осталось #2."
            }
            act(format, .toSleeping, .toCreature(self), .number(experience), .number(experienceNeeded))
        }
        
        act("У Вас есть # стальн#(ая,ые,ых) монет#(а,ы,).", .toSleeping,
            .toCreature(self), .number(gold))

        if let player = player {
            let seconds = player.playedSecondsSaved + player.playedSecondsUnsaved
            let hours = (seconds / secondsPerRealHour) % 24 // 0..23 hours
            let days = (seconds / secondsPerRealDay) // 0..34 days
            //seconds -= (secondsPerRealDay * days)
            
            act("Вы играете #1 д#1(ень,ня,ней) и #2 час#2(,а,ов).", .toSleeping,
                .toCreature(self), .number(Int(days)), .number(Int(hours)))
        }
    }
    
    func doOption(context: CommandContext) {
        guard !context.argument1.isEmpty else {
            showOptions()
            return
        }
        
        let name = context.argument1
        let value = context.argument2

        if name.isEqual(toOneOf: ["сброс", "reset"], caseInsensitive: false) {
            player?.preferenceFlags = PlayerPreferenceFlags.defaultFlags
            player?.mapWidth = defaultMapWidth
            player?.mapHeight = defaultMapHeight
            player?.pageWidth = defaultPageWidth
            player?.pageLength = defaultPageLength
            wimpLevel = 0
            player?.maxIdle = defaultMaxIdle
            send("Все настройки сброшены в состояние по умолчанию.")
        } else if option(name, matches: "краткий", "brief") {
            toggleOnOff(.brief, value,
                        "Теперь Вы не будете получать описания комнат.",
                        "Теперь Вы будете получать описания комнат.")

        } else if option(name, matches: "компактный", "compact") {
            toggleOnOff(.compact, value,
                       "Теперь Вы не будете получать дополнительную пустую строку перед статусом.",
                       "Теперь Вы будете получать дополнительную пустую строку перед статусом.")

        } else if option(name, matches: "именительный", "nominative") {
            toggleOnOff(.nominative, value,
                        "Теперь Вы будете видеть имена персонажей только в именительном падеже.",
                        "Теперь Вы будете видеть имена персонажей в необходимых падежах.")
            
        } else if option(name, matches: "передвижение", "movement") {
            toggleOnOff(.hideTeamMovement, value,
                       "Теперь Вы будете получать сообщения о перемещении только тех, кто не входит в Вашу группу.",
                       "Теперь Вы будете получать сообщения о перемещении всех.")
            
        } else if option(name, matches: "монстры", "mobiles") {
            toggleOnOff(.stackMobiles, value,
                        "Группировка одинаковых монстров включена.",
                        "Группировка одинаковых монстров отключена.")

        } else if option(name, matches: "предметы", "objects", "items") {
            toggleOnOff(.stackItems, value,
                        "Группировка одинаковых предметов включена.",
                        "Группировка одинаковых предметов отключена.")

        } else if option(name, matches: "карта", "map") && level >= Level.minimumMapLevel {
            if var mapSize = UInt8(value) {
                mapSize = clamping(mapSize, to: validMapSizeRange)
                // Allow only non-even map sizes
                mapSize += (1 - mapSize % 2)
                player?.mapWidth = mapSize
                player?.mapHeight = mapSize
                player?.preferenceFlags.insert(.map)
                send("Мини-карта области включена, размер \(mapSize)х\(mapSize) клет\(mapSize.ending("ка","ки","ок")).")
            } else {
                toggleOnOff(.map, value,
                            "Мини-карта области включена.",
                            "Мини-карта области отключена.")
            }
        } else if option(name, matches: "картография", "automapper") {
            toggleOnOff(.automapper, value,
                        "Поддержка средств составления карт включена.",
                        "Поддержка средств составления карт отключена.")

        } else if option(name, matches: "занят", "busy") {
            toggleOnOff(.busy, value,
                        "Теперь Вы не сможете вступать в разговоры.",
                        "Теперь Вы сможете вступать в разговоры.")
            
        } else if option(name, matches: "глух", "deaf") {
            toggleOnOff(.deaf, value,
                        "Теперь Вы не будете слышать крики.",
                        "Теперь Вы будете слышать крики.")
            
        } else if option(name, matches: "ответ", "reply") {
            toggleOnOff(.reply, value,
                        "Теперь Вы будете принимать ответы из невидимости.",
                        "Теперь Вы не будете принимать ответы из невидимости.")
            
        } else if option(name, matches: "перезаучивание", "rememorize") {
            toggleOnOff(.rememorize, value,
                        "Теперь Вы будете автоматически перезаучивать заклинания.",
                        "Теперь Вы не будете автоматически перезаучивать заклинаний.")

        } else if option(name, matches: "страница", "page") {
            togglePageLength(value)

        } else if option(name, matches: "ширина", "width") {
            togglePageWidth(value)

        } else if option(name, matches: "разбиение", "split") {
            toggleOnOff(.split, value,
                        "Теперь длинные строки будут автоматически разбиваться на несколько коротких. Если Ваш клиент не выделяет строки состояний из общего потока текста, то этот режим использовать не следует.",
                        "Теперь длинные строки не будут автоматически разбиваться на несколько коротких.")

        } else if option(name, matches: "постой", "rent") {
            toggleOnOff(.rentBank, value,
                        "Теперь Вы будете оплачивать постой сначала с банковского счета, затем наличными.",
                        "Теперь Вы будете оплачивать постой сначала наличными, затем с банковского счета.")

        } else if option(name, matches: "простой", "idle") {
            toggleMaxIdle(value)

        } else if option(name, matches: "трусость", "wimpy") {
            toggleWimpy(value)

        } else if option(name, matches: "тренировка", "training") {
            toggleOnOff(.training, value,
                        "Вы начали тренировку и не будете получать опыт.",
                        "Вы прекратили тренировку и будете получать опыт, как обычно.")
        
        } else if option(name, matches: "продолжать", "keep") {
            toggleOnOff(.keepFighting, value,
                        "Теперь Вы будете продолжать бой даже при потере соединения.",
                        "Теперь Вы будете автоматически убегать из боя при потере соединения.")
            
        } else if option(name, matches: "численность", "quantity") {
            toggleOnOff(.quantity, value,
                       "Теперь после списка группы Вам сообщат ее численность (если вы лидер).",
                       "Теперь информация о численности группы сообщаться не будет.")
            
        } else if option(name, matches: "направления", "fulldirs") {
            toggleOnOff(.fullDirections, value,
                        "Теперь команды направлений необходимо вводить полностью.",
                        "Теперь Вы можете использовать сокращения для команд направлений.")
            
        } else if option(name, matches: "статус", "status") {
            toggleStatus(value)
        
        } else if level >= settings.autostatMinLevel && option(name, matches: "статистика", "statistics") {
            toggleOnOff(.autostat, value,
                        "Теперь Вы будете видеть виртуальные номера объектов.",
                        "Теперь Вы не будете видеть виртуальные номера объектов.")
            
        } else if level >= settings.noHassleMinLevel && option(name, matches: "неуязвимость", "nohassle") {
            toggleOnOff(.noHassle, value,
                        "Теперь Вы неуязвимы.",
                        "Теперь Вы уязвимы.")

        } else if level >= settings.noHassleMinLevel && option(name, matches: "неуязвимость", "nohassle") {
            toggleOnOff(.noHassle, value,
                        "Теперь Вы неуязвимы.",
                        "Теперь Вы уязвимы.")

        } else if level >= settings.holylightMinLevel && option(name, matches: "всевидение", "holylight") {
            toggleOnOff(.holylight, value,
                        "Теперь Вы всевидящи.",
                        "Вы более не всевидящи.")

        } else {
            send("Неверное название режима.")
            return
        }
        
        player?.scheduleForSaving()
    }
    
    private func showOptions() {
        guard let preferenceFlags = preferenceFlags else {
            send("Выбор режимов недоступен.")
            return
        }
        
        //let color = onOff(preferenceFlags.contains(.color))
        let brief = onOff(preferenceFlags.contains(.brief))
        let compact = onOff(preferenceFlags.contains(.compact))
        let nominative = onOff(preferenceFlags.contains(.nominative))
        let movement = onOff(preferenceFlags.contains(.hideTeamMovement))
        let stackMobiles = onOff(preferenceFlags.contains(.stackMobiles))
        let stackItems = onOff(preferenceFlags.contains(.stackItems))
        let automapper = onOff(preferenceFlags.contains(.automapper))
        //send("цвет            Цвет: \(color).")
        send("краткий         Не показывать описания комнат: \(brief).")
        send("компактный      Не добавлять пустую строку перед статусом: \(compact).")
        send("именительный    Выводить имена персонажей только в именительном падеже: \(nominative).")
        send("передвижение    Пропускать сообщения о групповом передвижении: \(movement).")
        send("монстры         Группировка одинаковых монстров: \(stackMobiles).")
        send("предметы        Группировать предметы: \(stackItems).")
        if level >= Level.minimumMapLevel {
            let map = onOff(preferenceFlags.contains(.map))
            send("карта           Отображать карту области: \(map).")
        }
        send("картография     Поддержка средств составления карты: \(automapper).")
        send("")
        
        let busy = onOff(preferenceFlags.contains(.busy))
        let deaf = onOff(preferenceFlags.contains(.deaf))
        let reply = onOff(preferenceFlags.contains(.reply))
        send("занят           Не вступать в разговоры: \(busy).")
        send("глухой          Не слышать крики: \(deaf).")
        send("ответ           Принимать ответы из невидимости: \(reply).")
        send("")

        let rememorize = onOff(preferenceFlags.contains(.rememorize))
        send("перезаучивание  Автоматически перезаучивать заклинания: \(rememorize).")
        send("")
 
        let split = onOff(preferenceFlags.contains(.split))
        send("страница        Количество строк на странице: \(pageLength).")
        send("ширина          Ширина строки: \(pageWidth) символ\(pageWidth.ending("", "а", "ов")).")
        send("разбиение       Разбивать все строки по ширине (не рекомендуется): \(split).")
        send("")
        
        let fullDirections = onOff(preferenceFlags.contains(.fullDirections))
        let rentBank = onOff(preferenceFlags.contains(.rentBank))
        let keepFighting = onOff(preferenceFlags.contains(.keepFighting))
        let quantity = onOff(preferenceFlags.contains(.quantity))
        let training = onOff(preferenceFlags.contains(.training))
        send("направления     Не использовать сокращения для команд направлений: \(fullDirections).")
        send("постой          Оплачивать постой через банк: \(rentBank).")
        send("продолжать      Продолжать бой (не убегать) при потере соединения: \(keepFighting).")
        send("численность     Сообщать численность группы и количество \"свободных мест\": \(quantity).")
        if let player = controllingPlayer {
            send("простой         Разрывать соединение, если прстой привысил: \(player.maxIdle) минут\(player.maxIdle.ending("у", "ы", "")).")
        }
        send("тренировка      Не получать опыт за смерть монстра: \(training).")
        send("трусость        Уровень трусости: \(wimpLevel)%.")
        send("")
        
        var modes = ""
        if preferenceFlags.contains(.displayHitPointsInPrompt) { modes += "Ж" }
        if preferenceFlags.contains(.displayMovementInPrompt) { modes += "Б" }
        if preferenceFlags.contains(.displayXpInPrompt) { modes += "О" }
        if preferenceFlags.contains(.displayCoinsInPrompt) { modes += "М" }
        if preferenceFlags.contains(.autoexit) { modes += "В" }
        if preferenceFlags.contains(.autoexitEng) { modes += "А" }
        if preferenceFlags.contains(.nohpmvWhenMax) { modes += "С" }
        if preferenceFlags.contains(.dispmem) { modes += "З" }
        if preferenceFlags.contains(.displag) { modes += "П" }
        send("статус          Состав строки статуса: \(!modes.isEmpty ? modes : "ничего").")
        
        if level > Level.hero {
            send("")

            if level >= settings.autostatMinLevel {
                let autostat = onOff(preferenceFlags.contains(.autostat))
                send("статистика      Отображать виртуальные номера объектов: \(autostat)")
            }
            
            if level >= settings.noHassleMinLevel {
                let noHassle = onOff(preferenceFlags.contains(.noHassle))
                send("неуязвимость    Неуязвимость: \(noHassle)")
            }
            
            if level >= settings.holylightMinLevel {
                let holylight = onOff(preferenceFlags.contains(.holylight))
                send("всевидение      Всевидение: \(holylight)")
            }
        }
    }

    private func option(_ name: String, matches strings: String...) -> Bool {
        return name.isAbbreviation(ofOneOf: strings, caseInsensitive: true)
    }
        
    private func toggleOnOff(_ what: PlayerPreferenceFlags, _ value: String, _ on: String, _ off: String) {
        guard var newFlags = preferenceFlags else {
            send("Установка режимов недоступна.")
            return
        }
        
        if value.isEmpty {
            if newFlags.contains(what) {
                newFlags.remove(what)
            } else {
                newFlags.insert(what)
            }
        } else if value.isAbbreviation(ofOneOf: ["включен", "да", "on", "yes"], caseInsensitive: true) {
            newFlags.insert(what)
        } else if value.isAbbreviation(ofOneOf: ["выключен", "нет", "off", "no"], caseInsensitive: true) {
            newFlags.remove(what)
        } else {
            send("Укажите состояние режима \"включен\" или \"выключен\".")
            return
        }
            
        preferenceFlags = newFlags
        
        if newFlags.contains(what) {
            send(on)
        } else {
            send(off)
        }
    }
    
    private func togglePageLength(_ value: String) {
        guard !value.isEmpty, let newPageLength = Int16(value) else {
            send("Укажите число строк на странице в диапазоне 20-255 или 0 для значения по умолчанию.")
            return
        }
        
        guard newPageLength == 0 || (newPageLength >= 20 && newPageLength <= 255) else {
            send("Значение должно быть 0 или в диапазоне 20-255.")
            return
        }

        pageLength = newPageLength != 0 ? newPageLength : defaultPageLength
        act("Теперь у Вас будет # строк#(а,и,) на странице.", .toSleeping,
            .toCreature(self), .number(Int(pageLength)))
    }
    
    private func togglePageWidth(_ value: String) {
        guard !value.isEmpty, let newPageWidth = Int16(value) else {
            send("Укажите число символов на строке в диапазоне 40-255 или 0 для значения по умолчанию.")
            return
        }
        
        guard newPageWidth == 0 || (newPageWidth >= 40 && newPageWidth <= 255) else {
            send("Значение должно быть 0 или в диапазоне 40-255.")
            return
        }

        pageWidth = newPageWidth != 0 ? newPageWidth : defaultPageWidth
        act("Теперь у Вас будет # символ#(,а,ов) на строке.", .toSleeping,
            .toCreature(self), .number(Int(pageWidth)))
    }
    
    private func toggleMaxIdle(_ value: String) {
        guard !value.isEmpty, var newMaxIdle = Int(value) else {
            send("Укажите предел времени простоя в диапазоне (maxIdleTimeAllowedInterval.lowerBound)-\(maxIdleTimeAllowedInterval.upperBound) или 0 для значения по умолчанию.")
            return
        }
        
        guard newMaxIdle == 0 || (newMaxIdle >= maxIdleTimeAllowedInterval.lowerBound && newMaxIdle <= maxIdleTimeAllowedInterval.upperBound) else {
            send("Значение должно быть 0 или в диапазоне \(maxIdleTimeAllowedInterval.lowerBound)-\(maxIdleTimeAllowedInterval.upperBound).")
            return
        }
        
        if newMaxIdle == 0 {
            newMaxIdle = defaultMaxIdle
        }
        controllingPlayer?.maxIdle = newMaxIdle
        act("Теперь Вы будете отсоединены через # минут#(у,ы,) простоя.", .toSleeping,
            .toCreature(self), .number(newMaxIdle))
    }
    
    private func toggleWimpy(_ value: String) {
        guard !value.isEmpty, let newWimpy = UInt8(value) else {
            send("Укажите уровень трусости в диапазоне 0-25.")
            return
        }
        
        guard newWimpy >= 0 && newWimpy <= 25 else {
            send("Значение должно быть в диапазоне от 0 до 25.")
            return
        }
        
        wimpLevel = newWimpy
        send("Теперь Ваш уровень трусости \(wimpLevel).")
    }
    
    private func toggleStatus(_ value: String) {
        guard !value.isEmpty else {
            send("Укажите информацию, которую необходимо включить в строку состояния:\n" +
                "Ж - ваша текущая жизнь;\n" +
                "Б - ваша текущая бодрость;\n" +
                "О - опыт, необходимый для получения следующего уровня;\n" +
                "М - количество стальных монет у Вас в руках;\n" +
                "З - время, оставшееся до окончания запоминания заклинаний;\n" +
                "В - очевидные выходы из комнаты;\n" +
                "А - очевидные выходы из комнаты на английском языке;\n" +
                "К - не выводить текущую жизнь и бодрость при максимальном значении;\n" +
                "П - показывать, когда персонаж находится в состоянии \"паузы\";\n" +
                "все - первые шесть из вышеперечисленных режимов.")
            return
        }
        
        guard var newFlags = preferenceFlags else {
            send("Настройка строки состояния недоступна.")
            return
        }
        
        // Not using abbrevs because it's too easy to hit single letter token
        if value.isEqual(toOneOf: ["все", "all"], caseInsensitive: true) {
            newFlags.insert(.displayHitPointsInPrompt)
            newFlags.insert(.displayXpInPrompt)
            newFlags.insert(.displayMovementInPrompt)
            newFlags.insert(.displayCoinsInPrompt)
            newFlags.insert(.dispmem)
            newFlags.insert(.displag)
            newFlags.insert(.autoexit)
            send("Ваша строка состояния будет показывать всю доступную информацию.")
        } else {
            for c in value.lowercased() {
                guard !c.isWhitespace else { continue }
                
                switch c {
                case "ж", "h":
                    newFlags.insert(.displayHitPointsInPrompt)
                    send("Ваша статусная строка будет показывать текущую жизнь.")
                    break;
                case "б", "v":
                    newFlags.insert(.displayMovementInPrompt)
                    send("Ваша статусная строка будет показывать текущую бодрость.")
                    break;
                case "о", "x":
                    newFlags.insert(.displayXpInPrompt)
                    send("Ваша статусная строка будет показывать оставшийся до следующего уровня опыт.")
                    break;
                case "м", "c":
                    newFlags.insert(.displayCoinsInPrompt)
                    send("Ваша статусная строка будет показывать число стальных монет на руках.")
                    break;
                case "з", "m":
                    newFlags.insert(.dispmem)
                    send("Ваша статусная строка будет показывать время запоминания.")
                    break;
                case "п", "l":
                    newFlags.insert(.displag)
                    send("Ваша статусная строка будет показывать пребывание в состоянии паузы.")
                    break;
                case "в", "e":
                    newFlags.insert(.autoexit)
                    send("Ваша статусная строка будет показывать очевидные выходы из комнаты.")
                    break;
                case "а", "a":
                    newFlags.insert(.autoexitEng)
                    send("Ваша статусная строка будет показывать очевидные выходы из комнаты на английском языке.")
                    break;
                case "к", "b":
                    newFlags.insert(.nohpmvWhenMax)
                    send("Ваша статусная строка не будет показывать жизнь и бодрость на максимуме.")
                    break;
                default:
                    send("Допустимые символы: Ж, Б, О, М, З, В, А, К, П.")
                    break;
                }
            }
        }
        
        preferenceFlags = newFlags
    }
}

extension Creature {
    func doHelp(context: CommandContext) {
        let separator = " "
        let groupSuffix = ":"
        send("Основные команды RMUD\n")
        let commandGroups = commandInterpreter.commandGroups
        let groupNameMaxLength = commandGroups.orderedKeys.max {
            $1.count > $0.count 
        }?.count ?? 0
        for groupName in commandGroups.orderedKeys {
            let paddedGroupName = groupName.leftExpandingTo(minimumLength: groupNameMaxLength, with: " ")
            var line = "\(bCyn())\(paddedGroupName.uppercased())\(groupSuffix)\(nNrm())"
            var lineLength = groupName.count + groupSuffix.count // without ANSI codes
            for commandAbbreviation in commandGroups[groupName] ?? [] {
                let command = commandAbbreviation.command
                let restOfCommand = command.suffix(command.count - commandAbbreviation.abbreviation.count)
                let newTextLength = (line.isEmpty ? 0 : separator.count) + command.count
                if lineLength + newTextLength > pageWidth {
                    send(line)
                    let indent = paddedGroupName.count + groupSuffix.count
                    line = String(repeating: " ", count: indent)
                    lineLength = indent
                }
                if !line.isEmpty {
                    line += separator
                }
                line += "\(bGrn())\(commandAbbreviation.abbreviation)\(nNrm())\(restOfCommand)"
                lineLength += newTextLength
            }
            send(line)
        }
        send("\nПодробная информация доступна по команде СПРАВКА [команда]")
    }
}