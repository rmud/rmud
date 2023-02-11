import Foundation
//import SwiftSMTP
#if os(Linux)
import BSD
#endif

enum ReconnectMode {
    case noExistingCharactersFound
    case unswitch
    case usurp
    case reconnect
}

// Deal with newcomers and other non-playing sockets
func nanny(_ d: Descriptor, line: String) {
    if !d.isEchoOn {
        // When input echoing is disabled, CR typed by user after prompt isn't visible too. Add CR before printing new text:
        d.send("")
    }
    
    let arg = line.trimmingCharacters(in: .whitespaces)
    
    switch d.state {
    case .getCharset:
        stateGetCharset(d, arg)
    
    case .getAccountName:
        guard !arg.isEmpty else { break }
        
        let email = arg.lowercased()
        if !Email.isValidEmail(email) {
            d.send("Некорректный email.")
            break
        }

        guard let account = accounts.byLowercasedEmail[email] else {
            d.send("Этот email ранее не использовался.")

            let account = Account(uid: accounts.createAccountUid())
            account.email = email
            d.account = account
            accounts.insert(account: account)
            
            d.state = .confirmAccountCreation
            break
        }
        d.account = account
        if !account.flags.contains(.confirmationEmailSent) {
            d.disconnectOtherDescriptorsWithMyAccount()
            d.state = .confirmAccountCreation
        } else if !account.flags.contains(.passwordSet) {
            d.disconnectOtherDescriptorsWithMyAccount()
            // Authenticate account by email code if password is still not set
            d.state = .verifyConfirmationCode
        } else {
            d.state = .accountPassword
        }
        
    case .accountPassword:
        stateAccountPassword(d, arg)

    case .confirmAccountCreation:
        let account = d.account!
        if arg.isAbbrevCI(ofAny: ["да", "yes"]) {
            account.confirmationCode = arc4random_uniform(100000)
            sendConfirmationCodeEmail(account: d.account!)
            account.flags.insert(.confirmationEmailSent)
            account.scheduleForSaving()
            d.send("""
                   На Ваш email выслано письмо с кодом подтверждения. Если оно не придёт
                   в течение 5 минут, пожалуйста, свяжитесь с тех.поддержкой игры: support@rmud.org
                   """)

            d.state = .verifyConfirmationCode
        } else if arg.isAbbrevCI(ofAny: ["нет", "no"]) {
            accounts.remove(account: account)
            d.account = nil
            d.state = .getAccountName
        } else {
            d.send("Введите \"да\" или \"нет\".")
        }

    case .verifyConfirmationCode:
        let account = d.account!
        guard let confirmationCode = UInt32(arg),
                confirmationCode == account.confirmationCode else {
            d.send("Некорректный код потверждения.")
            break
        }
        d.state = .newPassword
        
    case .newPassword:
        let (isValid, reason) = isValidPassword(arg, descriptor: d)
        if !isValid {
            d.send(reason)
            break
        }
        d.account?.password = arg
        d.state = .confirmPassword

    case .confirmPassword:
        let account = d.account!
        
        if arg != account.password {
            d.send("Пароли не совпадают.")
            account.password = ""
            d.state = .newPassword
            break
        }
        
        account.flags.insert(.passwordSet)
        account.scheduleForSaving()
        
        d.echoOn()
        
        d.send("Учетная запись создана. Для игры необходимо создать персонажа.")
        d.send(playerNameRules)
        d.state = .getNameReal

    case .getNameReal:
        if arg.isEmpty {
            break
        }
        let name = argToPlayerName(arg)
        do {
            let (isValid, reason) = validateName(name: name, isNominative: true)
            if !isValid {
                d.send(reason)
                break
            }
        }
        
        do {
            let (isValid, reason) = validateNewName(name: name, nameNominative: nil)
            if !isValid {
                d.send(reason)
                log("Host [\(d.ip), \(d.hostname)] attempted to create a character with invalid name: \(name)")
                logToMud("Попытка создать персонажа с недопустимым именем \(name) [\(d.ip), \(d.hostname)].",
                    verbosity: .normal)
                break
            }
        }
        
        let creature = Creature(uid: db.createUid())
        creature.player = Player(creature: creature, account: d.account!)
        creature.nameNominative = MultiwordName(name)
        d.creature = creature
        
        d.state = .nameConfirmation

        
//    case .getName:
//        if arg.isEmpty {
//            //d.state = .close // why? just retry
//            break
//        }
//
//        if arg.isEqualCI(toAny: ["новый", "new"]) {
//
//            d.send(playerNameRules)
//            d.state = .getNameReal
//            break
//        }
//
//        let name = argToPlayerName(arg)
//        let (isValid, reason) = validateName(name: name, isNominative: true)
//        if !isValid {
//            d.send(reason)
//            break
//        }
//
//        guard let creature = players.getPlayer(name: name),
//                let player = creature.player else {
//            d.send("Персонажа с таким именем не существует")
//            break
//        }
//
//        assert(d.creature == nil)
//
//        d.creature = creature
//
//        // Оно потом ещё раз повторится, но оно нам надо как можно раньше
//        if player.flags.contains(.invisibleStart) {
//            player.adminInvisibilityLevel = creature.level
//        }
//        d.state = .password

    case .nameConfirmation:
        if arg.isAbbrevCI(ofAny: ["да", "yes"]) {
            let creature = d.creature!
            let name = creature.nameNominative
            log("Host [\(d.ip), \(d.hostname)] starts creating a new character: \(name)")
            logToMud("Начинается создание нового персонажа \(name) [\(d.ip), \(d.hostname)].",
                verbosity: .complete)
            
            creature.gender = morpher.detectGender(name: creature.nameNominative.full)
            d.state = .qSex
            break
        } else if arg.isAbbrevCI(ofAny: ["нет", "no"]) {
            d.creature = nil
            d.state = .getNameReal
            break
        } else {
            d.send("Введите \"да\" или \"нет\".")
        }
    case .qSex:
        let creature = d.creature!
        let prepareNextQuestion: () -> () = {
            let (nameGenitive, nameDative, nameAccusative, nameInstrumental, namePrepositional) = morpher.generateNameCases(name: creature.nameNominative.full, gender: creature.gender)
            creature.nameGenitive = MultiwordName(nameGenitive)
            creature.nameDative = MultiwordName(nameDative)
            creature.nameAccusative = MultiwordName(nameAccusative)
            creature.nameInstrumental = MultiwordName(nameInstrumental)
            creature.namePrepositional = MultiwordName(namePrepositional)
            d.send("Введите падежи имени Вашего персонажа.")
            d.state = .getNameGenitive
        }
        if !arg.isEmpty {
            if arg.isAbbrevCI(ofAny: ["мужской", "male"]) {
                creature.gender = .masculine
                prepareNextQuestion()
                break
            }
            if arg.isAbbrevCI(ofAny: ["женский", "female"]) {
                creature.gender = .feminine
                prepareNextQuestion()
                break
            }
            d.send("Введите \"м\" или \"ж\".")
            break
        }
        prepareNextQuestion()
    case .getNameGenitive:
        let creature = d.creature!
        let name = argToPlayerName(!arg.isEmpty ? arg : creature.nameGenitive.full)
        let (isValid, reason) = validateNewName(name: name, nameNominative: creature.nameNominative.full)
        if !isValid {
            d.send(reason)
            break
        }
        creature.nameGenitive = MultiwordName(name)
        d.state = .getNameDative
    case .getNameDative:
        let creature = d.creature!
        let name = argToPlayerName(!arg.isEmpty ? arg : creature.nameDative.full)
        let (isValid, reason) = validateNewName(name: name, nameNominative: creature.nameNominative.full)
        if !isValid {
            d.send(reason)
            break
        }
        creature.nameDative = MultiwordName(name)
        d.state = .getNameAccusative
    case .getNameAccusative:
        let creature = d.creature!
        let name = argToPlayerName(!arg.isEmpty ? arg : creature.nameAccusative.full)
        let (isValid, reason) = validateNewName(name: name, nameNominative: creature.nameNominative.full)
        if !isValid {
            d.send(reason)
            break
        }
        creature.nameAccusative = MultiwordName(name)
        d.state = .getNameInstrumental
    case .getNameInstrumental:
        let creature = d.creature!
        let name = argToPlayerName(!arg.isEmpty ? arg : creature.nameInstrumental.full)
        let (isValid, reason) = validateNewName(name: name, nameNominative: creature.nameNominative.full)
        if !isValid {
            d.send(reason)
            break
        }
        creature.nameInstrumental = MultiwordName(name)
        d.state = .getNamePrepositional
    case .getNamePrepositional:
        let creature = d.creature!
        let name = argToPlayerName(!arg.isEmpty ? arg : creature.namePrepositional.full)
        let (isValid, reason) = validateNewName(name: name, nameNominative: creature.nameNominative.full)
        if !isValid {
            d.send(reason)
            break
        }
        creature.namePrepositional = MultiwordName(name)
        d.state = .qClass
    case .qClass:
        if arg.hasPrefix("?") {
            let classIndexString = arg.droppingPrefix().trimmingCharacters(in: .whitespaces)
            showClassHelp(d, classIndexString: classIndexString)
            break
        }
        guard let classId = chooseClass(classIndexString: arg) else {
            d.send("Неверный выбор.")
            break
        }
        
        d.creature?.classId = classId
        
        d.state = .qRace
        
    case .qRace:
        let creature = d.creature!
        guard let race = chooseRace(raceIndexString: arg, classId: creature.classId) else {
            d.send("Неверный выбор.")
            break
        }
        
        creature.race = race
        
        d.state = .qAlignment
        
    case .qAlignment:
        let creature = d.creature!
        guard let alignment = chooseAlignment(alignmentIndexString: arg, classId: creature.classId) else {
            d.send("Неверный выбор.")
            break
        }
        
        creature.realAlignment = alignment
        
        d.state = .loadRoom
        
    case .loadRoom:
        guard let loadRoom = chooseLoadRoom(loadRoomIndexString: arg) else {
            d.send("Неверный выбор.")
            break
        }
        
        d.creature?.player?.loadRoom = loadRoom
        
        d.state = .creatureCreationCompleted

    case .creatureCreationCompleted:
        let creature = d.creature!

        logToMud("Создан новый персонаж \(creature.nameNominative) [\(d.account!.email), \(d.ip), \(d.hostname)].", verbosity: .normal)
        log("New creature created: \(creature.nameNominative) [\(d.account!.email), \(d.ip), \(d.hostname)]")

        // Promote first player in game to implementor
        let player = creature.player!
        let targetLevel: UInt8
        if players.count == 0 {
            player.roles = .admin
            targetLevel = maximumMortalLevel
            
            creature.thirst = nil
            creature.hunger = nil
            creature.drunk = nil
        } else {
            targetLevel = 1
            player.preferenceFlags.insert(.reequip)

            creature.thirst = 24
            creature.hunger = 24
            creature.drunk = 0
            creature.gold = 10
        }
        creature.rollStartAbilities()
        
        player.createdAtGameTimeSeconds = gameTime.seconds
        player.createdAtRealWorldTime = time(nil)
        player.lastLogonAtRealWorldTime = player.createdAtRealWorldTime
        player.lastPlayedSecondsUnsavedCheckpointAt = player.createdAtGameTimeSeconds

        player.newsRecordsLastTimeRead = textFiles.newsEntriesCount

        // Initial hitpoints and level:
        creature.realMaximumHitPoints = creature.classId.info.startingHitPoints
        player.hitPointGains.append(UInt8(creature.realMaximumHitPoints))
        creature.level = 1

        // Use game's leveling mechanism for advancing levels (if needed):
        creature.experience = creature.classId.info.experience(forLevel: targetLevel)
        creature.adjustLevel()
        // Immortals over level 30 don't level automatically, so up the level manually:
        creature.level = targetLevel
        
        creature.hitPoints = creature.affectedMaximumHitPoints()
        creature.movement = creature.affectedMaximumMovement()
        
        player.scheduleForSaving()
        d.account?.creatures.insert(creature)
        // FIXME
        //save_char_safe(d->character, RENT_CRASH);
        // FIXME
        //ccb_list[d->host] = "8"; // задержка 8 минут на создание нового персонажа
        
        d.state = .accountMenu
    case .accountMenu:
        stateAccountMenu(d, arg)
    case .chooseCreature:
        if arg.isEqualCI(toAny: ["новый", "new"]) {
            d.state = .getNameReal
            break
        }
        guard let creature = chooseCreature(arg: arg, account: d.account!) else {
            d.send("Неверный выбор.")
            break
        }
        d.creature = creature
        d.state = .creatureMenu
    case .changeAccountPasswordGetOld:
        logFatal("Unimplemented state: \(d.state)")
    case .changeAccountPasswordGetNew:
        logFatal("Unimplemented state: \(d.state)")
    case .changeAccountPasswordConfirm:
        logFatal("Unimplemented state: \(d.state)")
    case .deleteAccountConfirmation1:
        logFatal("Unimplemented state: \(d.state)")
    case .deleteAccountConfirmation2:
        logFatal("Unimplemented state: \(d.state)")
    case .creatureMenu:
        stateCreatureMenu(d, arg)
    case .exDescription:
        logFatal("Unimplemented state: \(d.state)")
    case .deleteCreatureConfirmation1:
        let account = d.account!

        if arg != account.password {
            d.send("Неверный пароль.")
            d.echoOn()
            d.state = .creatureMenu
            break
        }
        
        d.echoOn()
        d.state = .deleteCreatureConfirmation2
    case .deleteCreatureConfirmation2:
        let creature = d.creature!
        let nameEnglish = { !creature.nameNominative.isEmpty ? creature.nameNominative.full : "without name" }
        let name = { !creature.nameNominative.isEmpty ? creature.nameNominative.full : "без имени" }

        if arg.isEqualCI(toAny: ["да", "yes"]) {
            if creature.player?.flags.contains(.frozen) ?? false {
                d.send("Этот персонаж сейчас не может быть удален.")
                log("Failed attempt to delete frozen creature '\(nameEnglish())' of level \(creature.level)")
                logToMud("Неудачная попытка удалить замороженного персонажа \(name()) уровня \(creature.level).", verbosity: .normal)
                d.state = .creatureMenu
                break
            }
            
            players.delete(creature: creature)
            
            d.send("Персонаж удален.")
            log("Creature '\(nameEnglish())' of level \(creature.level) deleted")
            logToMud("Персонаж \(name()) уровня \(creature.level) удален.", verbosity: .normal)
            
            d.state = .accountMenu
            break
        }
        
        d.send("Персонаж не удален.")
        
        log("Failed attempt to delete creature '\(nameEnglish())' of level \(creature.level)")
        logToMud("Неудачная попытка удалить персонажа \(name()) уровня \(creature.level).", verbosity: .normal)

        d.state = .creatureMenu
    //case .rmotd:
    //    d.state = .menu
    case .ban:
        logFatal("Unimplemented state: \(d.state)")
    case .close:
        break
    case .playing:
        assertionFailure()
    }
}

// Print initial payer dialog prompt, depending on player's state
func sendStatePrompt(_ d: Descriptor) {
    switch d.state {
    case .getCharset:
        d.sendPrompt("Please choose charset [u]: ")
    case .getAccountName:
        d.sendPrompt("Введите Ваш email: ")
    case .accountPassword:
        d.sendPrompt("Пароль: ")
        d.echoOff()
    case .confirmAccountCreation:
        d.sendPrompt("Создать новую учетную запись (да/нет)? ")
    case .verifyConfirmationCode:
        d.sendPrompt("Введите код подтверждения, полученный по email: ")
    case .newPassword:
        d.sendPrompt("Придумайте пароль: ")
        d.echoOff()
    case .confirmPassword:
        // Дополнительно \r\n потому что после "Введите пароль:" отключалось эхо и CR пользователя не был отпечатан
        d.sendPrompt("Введите пароль повторно: ")
        d.echoOff()
    case .getNameReal:
        d.sendPrompt("Введите имя Вашего нового персонажа: ")
    case .nameConfirmation:
        d.sendPrompt("Имя Вашего нового персонажа \(d.creature!.nameNominative). Верно (да/нет)? ")
    case .qSex:
        let creature = d.creature!
        d.sendPrompt("Выберите пол Вашего персонажа (мужской/женский) [\(creature.gender.singleLetter)]: ")
    case .getNameGenitive:
        // Дополнительно \r\n потому что после "Введите пароль повторно:" отключалось эхо и CR пользователя не был отпечатан
        d.sendPrompt("Родительный падеж (пример: меч кого?) [\(d.creature!.nameGenitive)]: ")
    case .getNameDative:
        d.sendPrompt("Дательный падеж (пример: сказать кому?) [\(d.creature!.nameDative)]: ");
    case .getNameAccusative:
        d.sendPrompt("Винительный падеж (пример: ударить кого?) [\(d.creature!.nameAccusative)]: ")
    case .getNameInstrumental:
        d.sendPrompt("Творительный падеж (пример: сражаться с кем?) [\(d.creature!.nameInstrumental)]: ")
    case .getNamePrepositional:
        d.sendPrompt("Предложный падеж (пример: думать о ком?) [\(d.creature!.namePrepositional)]: ")
    case .qClass:
        d.send("")
        classMenuShow(d)
        d.send("")
        d.send("Для справки перед номером поставьте знак вопроса, например: ?1")
        d.sendPrompt("Выберите профессию Вашего персонажа: ")
    case .qRace:
        d.send("")
        raceMenuShow(d)
        d.sendPrompt("Выберите расу Вашего персонажа: ")
    case .qAlignment:
        d.send("")
        alignmentMenuShow(d)
        d.sendPrompt("Выберите наклонности Вашего персонажа: ")
    case .loadRoom:
        d.send("")
        d.send(playerLoadRooms)
        d.sendPrompt("Выберите стартовый город: ")
    case .creatureCreationCompleted:
        // FIXME: untimely advice to newbies
        d.sendPrompt(
            "Новичкам рекомендуем начать знакомство с игрой с команд\n" +
            "НОВИЧОК, ПРАВИЛА, СПРАВКА, КОМАНДЫ.\n" +
            "\n" +
            "Создание персонажа завершено. Нажмите ВВОД.")
    case .accountMenu:
        d.send("")
        d.send("Главное меню.")
        d.send(accountMenu)
        d.sendPrompt("Сделайте выбор: ")
    case .chooseCreature:
        d.send("")
        d.send("Ваши персонажи:")
        for (index, creature) in d.account!.creaturesByName().enumerated() {
            let className = creature.classId.info.namesByGender[creature.gender]
            d.send("\(index + 1)) \(creature.nameNominative): \(className ?? "?") \(creature.level) уровня")
        }
        d.sendPrompt("Выберите персонажа или \"новый\" для создания нового: ")
    case .changeAccountPasswordGetOld:
        d.sendPrompt("Введите старый пароль: ")
        d.echoOff()
    case .changeAccountPasswordGetNew:
        d.sendPrompt("Введите новый пароль: ")
        d.echoOff()
    case .changeAccountPasswordConfirm:
        d.sendPrompt("Введите новый пароль повторно: ")
        d.echoOff()
    case .deleteAccountConfirmation1:
        d.sendPrompt("Для подтверждения введите Ваш пароль: ")
        d.echoOff()
    case .deleteAccountConfirmation2:
        d.sendPrompt("Вы удаляете эту учетную запись навсегда.\n" +
            "Вы абсолютно уверены, что действительно хотите это сделать?\n" +
            "Для подтверждения введите \"да\" полностью: ")
    case .creatureMenu:
        let creature = d.creature!
        let className = creature.classId.info.namesByGender[creature.gender]
        d.send("")
        d.send("Добро пожаловать на Кринн!\n\n" +
            "Вы \(creature.nameNominative), \(className ?? "?") \(creature.level) уровня.")
        d.send(creatureMenu)
        d.sendPrompt("Сделайте выбор: ")
        
    case .exDescription:
        // Пользователь вводит многострочное описание персонажа, ничего не печатать
        break
    case .deleteCreatureConfirmation1:
        d.sendPrompt("Для подтверждения введите Ваш пароль: ")
    case .deleteCreatureConfirmation2:
        d.sendPrompt("Вы удаляете этого персонажа навсегда.\n" +
            "Вы абсолютно уверены, что действительно хотите это сделать?\n" +
            "Для подтверждения введите \"да\" полностью: ")
    //case .rmotd:
    //    d.sendPrompt("*** НАЖМИТЕ ВВОД: ")
    case .ban:
        break
    case .close:
        break
    case .playing:
        assertionFailure()
    }
}

private func stateGetCharset(_ d: Descriptor, _ arg: String) {
    if arg.isEqualCI(to: "list") {
        d.send(selectCharset)
    } else if charsetParse(d, arg) {
        // Команда переключения в бинарный режим нужна Unix Telnet, иначе он не позволяет
        // вводить русские буквы.
        // Нельзя посылать эту команду клиентам, которые не дублируют IAC при отсылке маду!
        // Если послать команду такому клиенту, он может ответить, но ответ расшифровать будет нельзя,
        // потому что в данных IAC не продублированы, и, что самое плохое, ответ прийдет к маду
        // слившись со строкой, которую вводил пользователь в качестве имени. :(
        if !d.iacInBroken {
            d.switchToBinary()
            //d.suggestCompression()
        }
        // Show it after charset selection
        if !textFiles.gameLogo.isEmpty {
            // Normally won't do this, but before logo add extra empty line:
            d.send("")
            
            d.send(textFiles.gameLogo)
        }
        d.state = .getAccountName
    }
}

private func sendConfirmationCodeEmail(account: Account) {
    let confirmationCode = String(account.confirmationCode).leftExpandingTo(5, with: "0")

    let text = """
    Здравствуйте,
    
    Ваш адрес электронной почты указан при регистрации новой
    учетной записи в RMUD. Для подтверждения используйте код:

    \(confirmationCode)

    Если Вы не создавали учетную запись, пожалуйста, проигнорируйте
    это письмо.

    По всем вопросам обращайтесь в тех.поддержку: support@rmud.org

    С уважением,
    команда RMUD.

    --

    Dear User,

    Your email address was used for creation of new RMUD account.
    To confirm, please use the code:

    \(confirmationCode)

    If you weren't creating a new account, please ignore this message.

    On all questions, please contact the support: support@rmud.org

    Thanks,
    The RMUD Team.
    """

    log("New account: email: \(account.email), code: \(confirmationCode)")

    guard !settings.accountVerificationEmail.isEmpty &&
            !account.email.isEmpty &&
            !settings.mailServer.isEmpty &&
            !settings.mailServerPassword.isEmpty else {
        logWarning("Won't send email: mail server not configured.")
        return
    }

    DispatchQueue.global().async {
        let smtp = SMTP(hostname: settings.mailServer,
                        email: settings.accountVerificationEmail,
                        password: settings.mailServerPassword)
        smtp.sendEmail(from: "RMUD <\(settings.accountVerificationEmail)>",
            to: account.email,
            subject: "RMUD account confirmation",
            text: text)
    }
}

private func stateAccountPassword(_ d: Descriptor, _ arg: String) {
    d.echoOn()
    
    guard !arg.isEmpty else { return }
    
    let account = d.account!
    guard arg == account.password else {
        log("PASSWORD: invalid password for account [\(account.email), \(d.ip), \(d.hostname)]")
        logToMud("ПАРОЛЬ: введен неверный пароль учетной записи [\(account.email), \(d.ip), \(d.hostname)].",
            verbosity: .brief)

        d.badPasswordEntryAttempts += 1
        account.badPasswordSinceLastLogin += 1
        account.scheduleForSaving()

        d.send("Неверный пароль.")

        if d.badPasswordEntryAttempts >= 3 {
            d.state = .close
        }
        return
    }
    d.badPasswordEntryAttempts = 0

    let badPws = account.badPasswordSinceLastLogin
    if badPws != 0 {
        d.send("\u{0007}" +
            "\(Ansi.bRed)За время с последнего входа в игру " +
            "произошл\(badPws.ending("а", "и", "о")) \(badPws) " +
            "неудачн\(badPws.ending("ая", "ые", "ых")) " +
            "попыт\(badPws.ending("ка", "ки", "ок")) войти в игру этой " +
            "учетной записью!\(Ansi.nNrm)\n")

        account.badPasswordSinceLastLogin = 0
        account.scheduleForSaving()
    }

//    if creature.level >= Level.hero {
//        d.send(textFiles.imotd)
//    } else {
//        d.send(textFiles.motd)
//    }
//    d.state = .rmotd
    
    if account.creatures.isEmpty {
        d.send("Для игры необходимо создать персонажа.")
        d.send(playerNameRules)
        d.state = .getNameReal
    } else {
        d.state = .accountMenu
    }
}

private func stateAccountMenu(_ d: Descriptor, _ arg: String) {
    guard !arg.isEmpty else { return }

    switch arg {
    case "1": // Выбрать персонажа
        d.state = .chooseCreature
    case "2": // Изменить пароль учетной записи
        d.state = .changeAccountPasswordGetOld
    case "3": // Удалить учетную запись
        d.state = .deleteAccountConfirmation1
    case "0": // Выйти из игры
        d.send("До скорого!")
        d.state = .close
    default:
        d.send("Это не пункт меню.")
    }
}

private func stateCreatureMenu(_ d: Descriptor, _ arg: String) {
    guard !arg.isEmpty else { return }
    
    switch arg {
    case "1":
        let creature = d.creature!
        creature.descriptors.insert(d)
        
        if creature.inRoom == nil {
            let loadRoomVnum = creature.player!.loadRoom
            let loadRoom: Room
            if let room = db.roomsByVnum[loadRoomVnum] {
                loadRoom = room
            } else {
                logError("Game entry room \(loadRoomVnum) does not exist")
                guard let mortalStartRoom = db.roomsByVnum[vnumMortalStartRoom] else {
                    logError("Mortal start room \(vnumMortalStartRoom) does not exist")
                    logToMud("\(creature.nameNominative) не может войти в игру: отсутствует стартовая комната.",
                        verbosity: .brief)
                    d.send("Невозможно войти в игру.")
                    return
                }
                loadRoom = mortalStartRoom
            }

            creature.reset()
        
            creature.player?.lastIp = d.ip
            creature.player?.lastHostname = d.hostname

            d.send("\nПусть Ваш визит будет увлекательным!")

            //if let timeUntilReboot = timeUntilReboot {
            //    act("Через # минут#(у,ы,) будет произведена перезагрузка игры.", "!Мч", creature, timeUntilReboot)
            //}
            creature.teleportTo(room: loadRoom)
            
            creature.hitPoints = creature.affectedMaximumHitPoints()
            creature.movement = creature.affectedMaximumMovement()
            
            db.creaturesInGame.append(creature)
        }
        d.state = .playing
        creature.lookAtRoom(ignoreBrief: false)
        
    case "2":
        d.state = .chooseCreature

    case "5":
        d.state = .deleteCreatureConfirmation1
        
    case "0":
        d.state = .accountMenu
    default:
        d.send("Это не пункт меню.")
    }
}

private func charsetParse(_ d: Descriptor, _ arg: String) -> Bool {
    switch arg.lowercased() {
    case "u", "1", "": // UTF8
        d.charset = .utf8
    case "2": // ZMUD 3.0
        d.iacOutBroken = true
        d.iacInBroken = true
        fallthrough
    case "4": // ZMUD 7.0
        d.charset = .cp1251
        d.workaroundZmudCp1251ZBug = true
    case "w", "3": // CP-1251, JMC
        d.charset = .cp1251
    case "k":
        d.charset = .koi8r
    case "d":
        d.charset = .cp866
    default:
        d.send("Invalid charset, please try again.")
        return false
    }
    
    return true
}

private func argToPlayerName(_ arg: String) -> String {
    return arg.lowercased().capitalizingFirstLetter()
}

func validateName(name: String, isNominative: Bool) -> (isValid: Bool, reason: String) {
    let nameType = isNominative ? "Имя" : "Форма имени"
    
    let disallowedLetters = playerNameAllowedLettersLowercased.inverted
    if nil != name.lowercased().rangeOfCharacter(from: disallowedLetters, options: .caseInsensitive) {
        return (isValid: false, reason: "\(nameType) персонажа может содержать только русские буквы.")
    }
    return (isValid: true, reason: "")
}

private func validateNewName(name: String, nameNominative: String?) -> (isValid: Bool, reason: String) {
    // если не передели именительной формы, то это она и есть
    let isNominative = nameNominative == nil
    
    do {
        let (isValid, reason) = validateName(name: name, isNominative: isNominative)
        if !isValid {
            return (isValid: false, reason: reason)
        }
    }
    
    let nameType = isNominative ? "Имя" : "Форма имени"
    let nameTypePre = isNominative ? "В имени" : "В форме имени"
    
    if name.count < 3 {
        return (isValid: false, reason: "\(nameType) персонажа не может быть короче трех букв.")
    }
    
    if name.count > playerMaxNameLength {
        return (isValid: false, reason: "\(nameType) персонажа не может быть длиннее \(playerMaxNameLength) букв.")
    }
    
    if name.hasPrefixCI(oneOf: ["ъ", "ы", "ь"]) {
        return (isValid: false, reason: "\(nameType) персонажа не может начинаться буквы \"\(name.first!)\".")
    }
    
    do {
        let nameLowercased = name.lowercased()
        let characters = Array(nameLowercased)
        for at in 0 ..< characters.count - 2 {
            if characters[at + 1] == characters[at] &&
                characters[at + 2] == characters[at] {
                return (isValid: false, reason: "\(nameTypePre) персонажа не может быть трех или более одинаковых букв подряд.")
            }
        }
    }
    
    if isFillWord(name) || ban.isXName(name) {
        return (isValid: false,
                reason: "Недопустим\(isNominative ? "ое имя" : "ая форма имени")  персонажа.")
    }
    
    if isNominative {
        for d in networking.descriptors {
            if d.state != .playing, let creature = d.creature {
                let creatureName = creature.nameNominative.full
                if name.isEqualCI(to: creatureName) {
                    return (isValid: false, reason: "Персонаж с этим именем уже создается.")
                }
            }
        }
        

        // FIXME
//        for creature in db.mobilePrototypesByVnum.values {
//            if creature.isEqualToNameOrSynonym(name, cases: .nominative) {
//                return (isValid: false, reason: "Недопустимое имя персонажа: в игре существует монстр с таким именем.")
//            }
//        }
    } else { // !isNominative
        let commonPrefix = name.commonPrefix(with: nameNominative!, options: .caseInsensitive)
        if commonPrefix.count < 2 {
            return (isValid: false, reason: "Недопустимая форма имени персонажа.")
        }
    }
    
    return (isValid: true, reason: "")
}

private func isValidPassword(_ password: String, descriptor d: Descriptor) -> (isValid: Bool, reason: String) {
    if password.count < 3 {
        return (isValid: false, reason: "Пароль не может быть короче трех символов.")
    }
    
    if password.count > playerMaxPasswordLength {
        return (isValid: false, reason: "Пароль не может быть длиннее \(playerMaxPasswordLength) символов.")
    }

    if let creature = d.creature,
       password.isEqualCI(to: creature.nameNominative.full) {
        return (isValid: false, reason: "Пароль не может совпадать с именем Вашего персонажа.")
    }
    
    return (isValid: true, reason: "")
}

// Show available classes
private func classMenuShow(_ d: Descriptor) {
    var result = "Список профессий:"
    
    let creature = d.creature!
    for (index, classId) in ClassId.allClasses.enumerated() {
        guard classId.isPlayable() else { continue }
        guard let name = classId.info.namesByGender[creature.gender] else { fatalError() }
        result += "\n\(index  + 1). \(name.capitalizingFirstLetter())"
    }
    d.send(result)
}

private func chooseClass(classIndexString: String) -> ClassId? {
    guard let classIndex = Int(classIndexString) else { return nil }

    for (index, classId) in ClassId.allClasses.enumerated() {
        guard classId.isPlayable() else { continue }
        if index + 1 == classIndex {
            return classId
        }
    }
    
    return nil
}

private func showClassHelp(_ d: Descriptor, classIndexString: String)
{
    guard let _ /*classId*/ = chooseClass(classIndexString: classIndexString) else {
        d.send("Укажите номер профессии из списка.")
        return
    }

    // FIXME
    d.send("Справка недоступна.")
}

private func raceMenuShow(_ d: Descriptor) {
    var result = "Ваша профессия встречается у следующих рас:"
    
    let creature = d.creature!
    for (index, race) in Race.playerRaces.enumerated() {
        guard creature.classId.info.racesAllowed.contains(race) else { continue }
        let name = race.info.namesByGender[creature.gender]?.capitalizingFirstLetter() ?? "ошибка"
        result += "\n\(index + 1). \(name)"
    }
    d.send(result)
}

private func chooseRace(raceIndexString: String, classId: ClassId) -> Race? {
    guard let raceIndex = Int(raceIndexString) else { return nil }

    for (index, race) in Race.playerRaces.enumerated() {
        guard classId.info.racesAllowed.contains(race) else { continue }
        if index + 1 == raceIndex {
            return race
        }
    }
    
    return nil
}

private let alignments: [(Int, String)] = [
    (800, "Добрый"),
    (0, "Нейтральный"),
    (-800, "Злой")
]

private func alignmentMenuShow(_ d: Descriptor) {
    var result = "Ваш персонаж может иметь такие наклонности:"
    
    let creature = d.creature!

    for (index, (alignment, name)) in alignments.enumerated() {
        guard creature.classId.info.alignment.contains(alignment) else { continue }
        result += "\n\(index + 1). \(name)"
    }

    d.send(result)
}

private func chooseAlignment(alignmentIndexString: String, classId: ClassId) -> Alignment? {
    guard let alignmentIndex = Int(alignmentIndexString) else { return nil }
    
    for (index, (alignment, _)) in alignments.enumerated() {
        guard classId.info.alignment.contains(alignment) else { continue }

        if index + 1 == alignmentIndex {
            return Alignment(clamping: alignment)
        }
    }
    
    return nil
}

private func chooseLoadRoom(loadRoomIndexString: String) -> Int? {
    guard let loadRoomIndex = Int(loadRoomIndexString) else { return nil }
    
    switch loadRoomIndex {
    case 1: return vnumSolaceInn  // Утеха
    case 2: return vnumBaliforInn // Балифор
    case 3: return vnumHavenInn   // Гавань
    case 4: return vnumKalamanInn // Каламан
    case 5: return vnumHyloInn    // Хайлоу
    default: break
    }
    return nil
}

private func chooseCreature(arg: String, account: Account) -> Creature? {
    if let creatureIndex = Int(arg) {
        for (index, creature) in account.creaturesByName().enumerated() {
            if index + 1 == creatureIndex {
                return creature
            }
        }
    } else {
        for creature in account.creatures {
            if arg.isEqualCI(to: creature.nameNominative.full) {
                return creature
            }
        }
        for creature in account.creatures {
            if arg.isAbbrevCI(of: creature.nameNominative.full) {
                return creature
            }
        }
    }
    return nil
}

