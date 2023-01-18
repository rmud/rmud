import Foundation

class Account {
    var uid: UInt64 = 0
    var email = ""
    var flags: AccountFlags = []
    var confirmationCode: UInt32 = 0
    var password = ""
    var badPasswordSinceLastLogin = 0

    var creatures: Set<Creature> = []
    
    init(uid: UInt64) {
        self.uid = uid
    }
    
    init?(from configFile: ConfigFile) {
        guard let uid: UInt64 = configFile["УИД"] else { return nil }
        self.uid = uid
        
        email = configFile["ПОЧТА"] ?? ""
        flags = configFile["ФЛАГИ"] ?? []
        confirmationCode = configFile["ПОЧТА_КОД"] ?? 0
        password = configFile["ПАРОЛЬ"] ?? ""
        badPasswordSinceLastLogin = configFile["НЕУДАЧ"] ?? 0
    }

    func save(to configFile: ConfigFile) {
        configFile["УИД"] = uid
        configFile["ПОЧТА"] = email
        configFile["ФЛАГИ"] = flags
        configFile["ПОЧТА_КОД"] = confirmationCode
        configFile["ПАРОЛЬ"] = password
        configFile["НЕУДАЧ"] = badPasswordSinceLastLogin
    }
    
    func scheduleForSaving() {
        accounts.scheduledForSaving.insert(self)
    }
    
    func creaturesByName() -> [Creature] {
        return creatures.sorted {
            $0.nameNominative.full < $1.nameNominative.full
        }
    }
}

extension Account: Equatable {
    static func ==(lhs: Account, rhs: Account) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension Account: Hashable {
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}
