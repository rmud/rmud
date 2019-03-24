import Foundation

class Dns {
    typealias DnsEntry = (name: String, timeout: Int)

    static let sharedInstance = Dns()
    
    static let defaultTimeout = 10000

    var dnsCache = [String: DnsEntry]() // domain names resolution cache

    func loadCache() {
        dnsCache.removeAll(keepingCapacity: true)
        var dictionary: [String: String]
        do {
            dictionary = try loadDictionary(fromFilename: filenames.dns)
        } catch {
            logError("While loading DNS cache: \(error.userFriendlyDescription)")
            return
        }
        
        for entry in dictionary {
            let parts = entry.value.components(separatedBy: " ").filter{ !$0.isEmpty }
            guard parts.count == 2 else {
                logError("Skipping invalid DNS cache entry")
                continue
            }
            dnsCache[entry.key] = DnsEntry(name: parts.first!, timeout: Int(parts.last!) ?? 0)
        }
    }
    
    func saveCache() {
        var dictionary = [String: String]()
        for cacheEntry in dnsCache {
            dictionary[cacheEntry.key] = "\(cacheEntry.value.name) \(cacheEntry.value.timeout)"
        }
        do {
            try saveDictionary(dictionary, toFilename: filenames.dns)
        } catch {
            logError("While saving DNS cache: \(error.userFriendlyDescription)")
        }
    }

    func dnsResolve(_ peer: sockaddr_in) -> (host: String, name: String) {
        var peer = peer
        let host = String(cString: inet_ntoa(peer.sin_addr))

        if !settings.mudDns {
            return (host: host, name: host)
        }
        
        if var cacheEntry = dnsCache[host] {
            cacheEntry.timeout = Dns.defaultTimeout
            dnsCache[host] = cacheEntry
            return (host: host, name: cacheEntry.name)
        }
        
        log("Resolving: [\(host)]")
        logToMud("Запрос на расшифровку адреса [\(host)].",
            verbosity: .complete, minLevel: Level.lesserGod)

        var tm = time(nil)
        let resolved = gethostbyaddr(&peer.sin_addr,
                                     socklen_t(MemoryLayout.stride(ofValue: peer.sin_addr)),
                                     AF_INET)
        tm = time(nil) - tm

        if tm >= 2 {
            log("WARNING: resolving of [\(host)] took \(tm) second\(tm.ending("", "s", "s"))")
            logToMud("ВНИМАНИЕ: расшифровка адреса [\(host)] заняла \(tm) секунд\(tm.ending("у", "ы", "")).",
                verbosity: .normal, minLevel: Level.lesserGod)
        }

        guard let hostEntry = resolved?.pointee else {
            log("Unable to resolve [\(host)]")
            logToMud("ВНИМАНИЕ: не удалось расшифровать адрес [\(host)].",
                verbosity: .complete, minLevel: Level.lesserGod)
            return (host: host, name: host)
        }
        
        let resolvedName = String(cString: hostEntry.h_name)
        log("Host [\(host)] resolved to [\(resolvedName)]")
        logToMud("Адрес [\(host)] расшифрован в [\(resolvedName)].",
            verbosity: .complete, minLevel: Level.lesserGod)
        dnsCache[host] = DnsEntry(name: resolvedName, timeout: Dns.defaultTimeout)
        return (host: host, name: resolvedName)
    }
}

