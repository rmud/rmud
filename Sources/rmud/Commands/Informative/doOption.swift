extension Creature {
    func doOption(context: CommandContext) {
        guard let player = player else { return }

        guard !context.argument1.isEmpty else {
            showOptions()
            return
        }
        
        let name = context.argument1
        let value = context.argument2

        if name.isEqualCI(toAny: ["сброс", "reset"]) {
            player.preferenceFlags = PlayerPreferenceFlags.defaultFlags
            player.mapWidth = defaultMapWidth
            player.mapHeight = defaultMapHeight
            player.pageWidth = defaultPageWidth
            player.pageLength = defaultPageLength
            wimpLevel = 0
            player.maxIdle = defaultMaxIdle
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

        } else if option(name, matches: "путь", "path") {
            toggleOnOff(.goIntoUnknownRooms, value,
                        "Теперь Вы будете заходить в неизведанные места.",
                        "Теперь Вы будете останавливаться перед неизведанными местами.")

        } else if option(name, matches: "карта", "map") {
            if var mapSize = UInt8(value) {
                mapSize = clamping(mapSize, to: validMapSizeRange)
                // Allow only non-even map sizes
                mapSize += (1 - mapSize % 2)
                player.mapWidth = mapSize
                player.mapHeight = mapSize
                player.preferenceFlags.insert(.map)
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
        
        } else if player.roles.contains(.admin) && option(name, matches: "статистика", "statistics") {
            toggleOnOff(.autostat, value,
                        "Теперь Вы будете видеть виртуальные номера объектов.",
                        "Теперь Вы не будете видеть виртуальные номера объектов.")
            
        } else if player.roles.contains(.admin) && option(name, matches: "неуязвимость", "nohassle") {
            toggleOnOff(.godMode, value,
                        "Теперь Вы неуязвимы.",
                        "Теперь Вы уязвимы.")

        } else if player.roles.contains(.admin) && option(name, matches: "всевидение", "holylight") {
            toggleOnOff(.holylight, value,
                        "Теперь Вы всевидящи.",
                        "Вы более не всевидящи.")

        } else {
            send("Неверное название режима.")
            return
        }
        
        player.scheduleForSaving()
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
        let goIntoUnknownRooms = onOff(preferenceFlags.contains(.goIntoUnknownRooms))
        let map = onOff(preferenceFlags.contains(.map))
        let mapWidth = controllingPlayer?.mapWidth ?? defaultMapWidth
        let mapHeight = controllingPlayer?.mapHeight ?? defaultMapHeight
        let automapper = onOff(preferenceFlags.contains(.automapper))
        //send("цвет            Цвет: \(color).")
        send("краткий         Не показывать описания комнат: \(brief).")
        send("компактный      Не добавлять пустую строку перед статусом: \(compact).")
        send("именительный    Выводить имена персонажей только в именительном падеже: \(nominative).")
        send("передвижение    Пропускать сообщения о групповом передвижении: \(movement).")
        send("монстры         Группировка одинаковых монстров: \(stackMobiles).")
        send("предметы        Группировать предметы: \(stackItems).")
        send("путь            Заходить в неизведанные места: \(goIntoUnknownRooms).")
        send("карта           Отображать карту области: \(map).")
        send("карта <1-9>     Размер карты: \(mapWidth)х\(mapHeight) клет\(mapHeight.ending("ка","ки","ок")).")
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
        if let player = player {
            send("простой         Разрывать соединение, если простой привысил: \(player.maxIdle) минут\(player.maxIdle.ending("у", "ы", "")).")
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
        
        if player?.roles.contains(.admin) ?? false {
            send("")

            let autostat = onOff(preferenceFlags.contains(.autostat))
            send("статистика      Отображать виртуальные номера объектов: \(autostat)")
            
            let godMode = onOff(preferenceFlags.contains(.godMode))
            send("неуязвимость    Неуязвимость: \(godMode)")
            
            let holylight = onOff(preferenceFlags.contains(.holylight))
            send("всевидение      Всевидение: \(holylight)")
        }
    }

    private func option(_ name: String, matches strings: String...) -> Bool {
        return name.isAbbrevCI(ofAny: strings)
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
        } else if value.isAbbrevCI(ofAny: ["включен", "да", "on", "yes"]) {
            newFlags.insert(what)
        } else if value.isAbbrevCI(ofAny: ["выключен", "нет", "off", "no"]) {
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
            .to(self), .number(Int(pageLength)))
    }
    
    private func togglePageWidth(_ value: String) {
        let minPageWidth = 60
        let maxPageWidth = 255
        guard !value.isEmpty, let newPageWidth = Int16(value) else {
            send("Укажите число символов на строке в диапазоне \(minPageWidth)-\(maxPageWidth) или 0 для значения по умолчанию.")
            return
        }
        
        guard newPageWidth == 0 || (newPageWidth >= minPageWidth && newPageWidth <= maxPageWidth) else {
            send("Значение должно быть 0 или в диапазоне \(minPageWidth)-\(maxPageWidth).")
            return
        }

        pageWidth = newPageWidth != 0 ? newPageWidth : defaultPageWidth
        act("Теперь у Вас будет # символ#(,а,ов) на строке.", .toSleeping,
            .to(self), .number(Int(pageWidth)))
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
            .to(self), .number(newMaxIdle))
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
        if value.isEqualCI(toAny: ["все", "all"]) {
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
