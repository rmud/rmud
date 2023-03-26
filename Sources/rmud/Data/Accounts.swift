import Foundation

class Accounts {
    static let sharedInstance = Accounts()
    
    private(set) var byUid: [UInt64: Account] = [:]
    private(set) var byLowercasedEmail: [String: Account] = [:]
    var scheduledForSaving = Set<Account>()

    func load() {
        let directory = URL(fileURLWithPath: filenames.accountsPrefix, isDirectory: true)
        
        FileUtils.enumerateFiles(atPath: filenames.accountsPrefix, withExtension: "acc", flags: []) { filename, stop in

            do {
                let fullName = directory.appendingPathComponent(filename, isDirectory: false).relativePath

                let configFile = try ConfigFile(fromFile: fullName)
                guard !configFile.isEmpty else {
                    logFatal("Account file '\(filename)' is empty")
                }
                
                guard let account = Account(from: configFile) else {
                    logFatal("Invalid account file '\(filename)'")
                }

                byUid[account.uid] = account
                if !account.email.isEmpty {
                    byLowercasedEmail[account.email.lowercased()] = account
                }
            } catch {
                logFatal("Unable to load account '\(filename)': \(error.userFriendlyDescription)")
            }
        }
        let accountCount = byUid.count
        log("  \(accountCount) account\(accountCount.ending("", "s", "s"))")
    }
    
    func save() {
        guard !scheduledForSaving.isEmpty else { return }
        
        FileUtils.createDirectoryIfNotExists(filenames.accountsPrefix)
        
        let savedCount = scheduledForSaving.count
        for account in scheduledForSaving {
            let filename = filenames.accountFileName(forAccount: account)
            do {
                let configFile = ConfigFile()
                account.save(to: configFile)
                try configFile.save(toFile: filename, atomically: settings.saveFilesAtomically)
            } catch {
                logFatal("Unable to save account '\(account.email)': \(error.userFriendlyDescription)")
            }
        }
        scheduledForSaving.removeAll(keepingCapacity: true)
        log("Saved \(savedCount) account\(savedCount.ending("", "s", "s"))")
    }

    func insert(account: Account) {
        byUid[account.uid] = account
        if !account.email.isEmpty {
            byLowercasedEmail[account.email.lowercased()] = account
        }
    }
    
    func remove(account: Account) {
        byUid.removeValue(forKey: account.uid)
        if !account.email.isEmpty {
            byLowercasedEmail.removeValue(forKey: account.email)
        }
    }
    
    func createAccountUid() -> UInt64 {
        while true {
            let accountUid = UInt64.random()
            guard byUid[accountUid] == nil else { continue }
            return accountUid
        }
    }
}
