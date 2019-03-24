import Foundation

class Player {
    enum TitleOrder {
        case raceThenName
        case nameThenRace
    }
    
    var account: Account
    unowned var creature: Creature
    
    var nameCombined: String {
        // FIXME: xgaf rules are more complex
        get {
            return "(\(creature.nameNominative),\(creature.nameGenitive),\(creature.nameDative),\(creature.nameAccusative),\(creature.nameInstrumental),\(creature.namePrepositional))"
        }
        set {
            assignNameParts(nameCombined: newValue,
                            nominative: &creature.nameNominative,
                            genitive: &creature.nameGenitive,
                            dative: &creature.nameDative,
                            accusative: &creature.nameAccusative,
                            instrumental: &creature.nameInstrumental,
                            prepositional: &creature.namePrepositional)
        }
    }
    
    //var password = ""
    //var email = ""
    //var emailPwd = "" // для ВРЕМЕННОГО хранения почтового пароля

    var customTitle = ""
    
    func titleWithFallbackToRace(order: TitleOrder) -> String {
        if !customTitle.isEmpty {
            return customTitle
        }
        let raceName = creature.race.info.namesByGender[creature.gender] ?? "некто"
        switch order {
        case .raceThenName:
            return "\(raceName) \(creature.nameNominative)"
        case .nameThenRace:
            return "\(creature.nameNominative), \(raceName)"
        }
    }

    var language: Language = .russian
    //
    var flags: PlayerFlags = []
    var preferenceFlags: PlayerPreferenceFlags = PlayerPreferenceFlags.defaultFlags
    var mapWidth: UInt8 = defaultMapWidth
    var mapHeight: UInt8 = defaultMapHeight
    var hitPointGains: [UInt8] = [] // record HP gains for each level
    //
    // FIXME: do we need it?
    var spellSeparator: Character = "\"" // spellname separator
    var loadRoom = vnumMortalStartRoom // which room to enter game in
    var bankGold = 0 // bank account
    //
    // Admin's level of invisibility. Completely overrides game rules such as
    // glowing items exposing creatures, so do not use for gameplay purposes.
    var adminInvisibilityLevel: UInt8 = 0
    //
    // Same mob kill EXP gain limitation arrays
    typealias KillInfo = (vnum: Int, killCount: UInt16)
    var kills = [KillInfo]()

    var watching: Creature?
    
    var createdAtGameTimeSeconds: UInt64 = 0
    var createdAtRealWorldTime: time_t = 0
    var lastLogonAtRealWorldTime: time_t = 0
    var lastPlayedSecondsUnsavedCheckpointAt: UInt64 = 0
    var playedSecondsSaved: UInt64 = 0
    var playedSecondsUnsaved: UInt64 {
        get {
            return gameTime.seconds - lastPlayedSecondsUnsavedCheckpointAt
        }
        set {
            lastPlayedSecondsUnsavedCheckpointAt = gameTime.seconds - newValue
        }
    }
    //let time = TimeData() // player age
    var realAgeSeconds: UInt64 {
        return playerStartAgeYears * secondsPerGameYear + gameTime.seconds - createdAtGameTimeSeconds
    }
    func affectedAgeSeconds() -> UInt64 {
        return affected(baseValue: realAgeSeconds, by: .custom(.age), clampedTo: (10*secondsPerGameYear)...(1024*secondsPerGameYear))
    }
    
    //
    var newsRecordsLastTimeRead = 0 // number of news records last time read
    //
    // Page screen settings; 0 - use default
    var pageWidth: Int16 = defaultPageWidth
    var pageLength: Int16 = defaultPageLength
    //
    //    // Map size
    //    var mapWidth: UInt8 = 0
    //    var mapHeight: UInt8 = 0
    //
    var poofin = "" // description on arrival of a god
    var poofout = "" // description upon a god's exit
    var titleRequest = "" // pointer to title requested by player

    var lastTell: Int? = nil // idnum of last tell from (FIXME - get rid of idnums!)
    // FIXME: why update it every tic and not attach to game time?
    var noQuitTicsLeft: Int16 = 0 // for how many tics can't leave game
    var isNoQuit: Bool {
        return noQuitTicsLeft > 0
    }
    var noShoutTicsLeft: Int16 = 0 // for how many tics can't shout and yell

    var incomingTells = [String]() // last tells and whispers

    //var badPasswordSinceLastLogin = 0 // moved to Account
    var maxIdle = defaultMaxIdle // force-rent if idle that many ticks
    var lastIp = ""
    var lastHostname = "" // the last host name
    //
        var trackRdir: UInt8 = 0 // track skill improvement info
        var trackDblCrs: UInt8 = 0 // right direction & doublecrossed dirs
    //    var lastWildShift: UInt16 = 0 // Последнее смещение при потере ориентировки в ПРИРОДЕ
    //    var orientImprAt: Int = 0 // Следующий прирост ОРИЕНТИРОВАНИЯ не раньше...
    //    
    //    var lastTaskUid: Int = 0 // Номер последней ошибки, с которой работали
    //    
    //    var permition: UInt64 = 0 // уид игрока, которому позволено одно "опасное" заклинания в нан адрес

    var isMortalAndLinkDead: Bool {
        // FIXME: do not abuse nohassle and invis level
        return creature.level < Level.hero && adminInvisibilityLevel > 0 && preferenceFlags.contains(.noHassle)
    }
    
    init(creature: Creature, account: Account) {
        self.creature = creature
        self.account = account
    }
    
    // nameNominative is for logging only
    init(from playerFile: ConfigFile, nameNominative: String, creature: Creature) {
        self.creature = creature
        
        let s = "ОСНОВНАЯ"
        //let extra = "ДОПОЛНИТЕЛЬНАЯ"
        
        guard let accountUid: UInt64 = playerFile[s, "УЧЕТНАЯЗАПИСЬ"] else {
            logFatal("\(creature.nameNominative) has no account uid")
        }
        guard let account = accounts.byUid[accountUid] else {
            logFatal("\(creature.nameNominative) has unexistent account uid \(accountUid)")
        }
        self.account = account
        
        customTitle = playerFile[s, "ТИТУЛ"] ?? ""
        language = Language(rawValue: playerFile[s, "ЯЗЫК"] ?? 0) ?? .russian
        
        createdAtGameTimeSeconds = playerFile[s, "СОЗДАНИГРОВОЕ"] ?? gameTime.seconds
        createdAtRealWorldTime = playerFile[s, "CОЗДАН"] ?? 0
        playedSecondsSaved = playerFile[s, "ИГРАЛ"] ?? 0
        playedSecondsUnsaved = 0
        lastLogonAtRealWorldTime = playerFile[s, "ВХОДИЛ"] ?? 0
        
        bankGold = playerFile[s, "БАНК"] ?? 0
        
        flags = playerFile[s, "ФЛАГИ"] ?? []
        
        //email = playerFile[s, "ПОЧТА"] ?? ""

        do {
            let gainsString: String = playerFile[s, "ПРИРОСТЫ"] ?? ""
            let gains: [UInt8?] = gainsString.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .map {
                    guard let gain = UInt8($0), gain != 0 else { return nil }
                    return gain
                }
            for gainOrNil in gains {
                let gain = gainOrNil ?? 0
                hitPointGains.append(gain)
            }
        }
        
        do {
            // Note that these arrays will contain zeros in empty slots
            let killVnumsString = playerFile[s, "УБ.НОМ"] ?? ""
            let killVnums: [Int] = killVnumsString.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .map { Int($0) ?? 0 }
            let killCountsString = playerFile[s, "УБ.КОЛ"] ?? ""
            let killCounts: [UInt16] = killCountsString.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .map { UInt16($0) ?? 0 }
            if killVnums.count != killCounts.count {
                logError("Player \(nameNominative): kill vnums count (\(killVnums.count)) not equal to killCounts size (\(killCounts.count))")
            }
            let vnumsAndCounts = Array(zip(killVnums, killCounts))
            let killPosition = playerFile[s, "УБ.ПОЗ"] ?? vnumsAndCounts.count
            let vnumsAndCountsReordered =
                vnumsAndCounts[killPosition ..< vnumsAndCounts.count] +
                vnumsAndCounts[0 ..< killPosition]
            let vnumsAndCountsTrimmed = vnumsAndCountsReordered.filter {
                vnum, killCount in
                return vnum != 0 && killCount != 0
            }
            kills = vnumsAndCountsTrimmed.map { KillInfo(vnum: $0, killCount: $1) }
        }
        
        noShoutTicsLeft = playerFile[s, "ПРОСТУДА"] ?? 0
        adminInvisibilityLevel = playerFile[s, "НЕВИДИМОСТЬ"] ?? 0
        loadRoom = playerFile[s, "КОМНАТА"] ?? vnumMortalStartRoom
        preferenceFlags = playerFile[s, "РЕЖИМ"] ?? []
        mapWidth = playerFile[s, "КАРТА_ШИРИНА"] ?? defaultMapWidth
        mapHeight = playerFile[s, "КАРТА_ВЫСОТА"] ?? defaultMapHeight
        spellSeparator = playerFile[s, "РАЗДЕЛИТЕЛЬ"] ?? Character("\"")
        pageWidth = playerFile[s, "ШИРИНА"] ?? defaultPageWidth
        pageLength = playerFile[s, "ВЫСОТА"] ?? defaultPageLength
        newsRecordsLastTimeRead = playerFile[s, "НОВОСТЕЙ"] ?? 0
        maxIdle = playerFile[s, "ОЖИДАНИЕ"] ?? defaultMaxIdle
        
        //password = playerFile[s, "ПАРОЛЬ"] ?? ""
        
        poofin = playerFile[s, "ПРИБЫТИЕ"] ?? ""
        poofout = playerFile[s, "ОТБЫТИЕ"] ?? ""
        titleRequest = playerFile[s, "ЗАПРОСТИТУЛА"] ?? ""
        
        //badPasswordSinceLastLogin = playerFile[extra, "НЕУДАЧ"] ?? 0
    }
    
    func save(to configFile: ConfigFile) {
        let s = "ОСНОВНАЯ"

        configFile[s, "УЧЕТНАЯЗАПИСЬ"] = account.uid
        
        configFile[s, "ТИТУЛ"] = customTitle
        configFile[s, "ЯЗЫК"] = language.rawValue

//        /* Write PFF_NUM_AFFS field first so cache wouldn't miss on load: */
//        af = ch->affected;
//        num = 0;
//        while (af) {
//            af = af->next;
//            num++;
//        }
//        playerFile.setInt(sc, PFF_NUM_AFFS, num);
//        /* Now write the fields: */
//        af = ch->affected;
//        num = 0;
//        while (af) {
//            playerFile.setInt(sc, arrayFieldName(PFF_AFF_AR, num, PFF_AFF_TYPE), af->type);
//            playerFile.setInt(sc, arrayFieldName(PFF_AFF_AR, num, PFF_AFF_LEV), af->level);
//            playerFile.setInt(sc, arrayFieldName(PFF_AFF_AR, num, PFF_AFF_DUR), af->duration);
//            playerFile.setInt(sc, arrayFieldName(PFF_AFF_AR, num, PFF_AFF_COMBAT), af->combat_spell);
//            playerFile.setInt(sc, arrayFieldName(PFF_AFF_AR, num, PFF_AFF_LOC), af->location);
//            playerFile.setInt(sc, arrayFieldName(PFF_AFF_AR, num, PFF_AFF_MOD), af->modifier);
//            af = af->next;
//            num++;
//        }

        configFile[s, "СОЗДАНИГРОВОЕ"] = createdAtGameTimeSeconds
        configFile[s, "CОЗДАН"] = createdAtRealWorldTime
        do {
            playedSecondsSaved += playedSecondsUnsaved
            playedSecondsUnsaved = 0
            configFile[s, "ИГРАЛ"] = playedSecondsSaved
        }
        configFile[s, "ВХОДИЛ"] = lastLogonAtRealWorldTime

        configFile[s, "БАНК"] = bankGold
        
        configFile[s, "ФЛАГИ"] = flags
        
//        playerFile.setString(sc, PFF_EMAIL, ch->plr->email);

        configFile[s, "ПРИРОСТЫ"] = hitPointGains.map { String($0) }.joined(separator: ", ")

        configFile[s, "УБ.НОМ"] = kills.map { String($0.vnum) }.joined(separator: ", ")
        configFile[s, "УБ.КОЛ"] = kills.map { String($0.killCount) }.joined(separator: ", ")
        configFile[s, "УБ.ПОЗ"] = kills.count

        configFile[s, "ПРОСТУДА"] = noShoutTicsLeft
        configFile[s, "НЕВИДИМОСТЬ"] = adminInvisibilityLevel
        configFile[s, "КОМНАТА"] = loadRoom
        configFile[s, "РЕЖИМ"] = preferenceFlags
        configFile[s, "КАРТА_ШИРИНА"] = mapWidth
        configFile[s, "КАРТА_ВЫСОТА"] = mapHeight
        configFile[s, "РАЗДЕЛИТЕЛЬ"] = spellSeparator
        configFile[s, "ШИРИНА"] = pageWidth
        configFile[s, "ВЫСОТА"] = pageLength
        configFile[s, "НОВОСТЕЙ"] = newsRecordsLastTimeRead
        configFile[s, "ОЖИДАНИЕ"] = maxIdle

//        configFile.setString(sc, PFF_PASSWD, ch->plr->passwd);

        configFile[s, "ПРИБЫТИЕ"] = poofin
        configFile[s, "ОТБЫТИЕ"] = poofout
        configFile[s, "ЗАПРОСТИТУЛА"] = titleRequest

//        let extra = "ДОПОЛНИТЕЛЬНАЯ"

//        //////ZMEY: save BAD_PWS_ATTEMPT too

//        // Unused, not loaded
//        if (ch->desc && *ch->desc->host) {
//            configFile.setString(sc, PFF_EXT_HOST, ch->desc->host);
//        }
    }

    func scheduleForSaving() {
        players.scheduledForSaving.insert(creature)
    }
    
}
