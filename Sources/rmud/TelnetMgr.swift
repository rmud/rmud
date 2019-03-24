import Foundation

class TelnetMgr {
    var iacInBroken = false
    var compressOutput = false
    
    var unprocessedBuf = [CChar]()
    
    func process(data: [CChar], dataSize: Int) -> [CChar]? {
        unprocessedBuf += data[0 ..< dataSize]
        
        let len = unprocessedBuf.count
        
        var result = [CChar]()
        result.reserveCapacity(len * 2)
        
        let from = 0
        var p = 0
        let to = len
        stopParsing: while p != len {
            if unprocessedBuf[p] == telnet.iac && !iacInBroken {
                if p + 1 == to {
                    break stopParsing
                }
                switch unprocessedBuf[p + 1] {
                case telnet.iac:
                    // [IAC] [IAC]: convert to single IAC
                    // p is currently at first [IAC]
                    p += 1
                    // we've moved p to second IAC, so it will be copied to the resulting string
                case telnet.ga:
                    // [IAC] [GA]: end of output, skip both IAC and GA
                    // If not followed by \r\n,
                    p += 2
                    continue
                case telnet.sb:
                    // [IAC] [SB] ... [IAC] [SE] - skip everything between these sequences
                    var t = p
                    t += 2 // Skip [IAC] [SB]
                    var seqLen = 2
                    var foundIacSe = false
                    while t < to {
                        if unprocessedBuf[t] == telnet.iac && unprocessedBuf[t + 1] == telnet.se {
                            foundIacSe = true
                            break
                        }
                        t += 1
                        seqLen += 1
                    }
                    if foundIacSe {
                        p = t + 2 // skip everything including [IAC] [SE]
                        continue
                    }
                    // Sequence is incomplete, no [IAC] [SE]
                    // If sequence is too long, probably we're being abused
                    if seqLen > 30 {
                        return nil // close connection!
                    }
                    break stopParsing
                case telnet.will, telnet.wont, telnet.doCommand, telnet.dont:
                    // p is currently at [IAC]
                    // we've already verified that p+1 does exist, check for p+2:
                    if p + 2 == to {
                        break stopParsing // incomplete sequence, stop parsing
                    }
                    // process the known commands:
                    if unprocessedBuf[p + 1] == telnet.doCommand && unprocessedBuf[p + 2] == telnet.teloptCompress2 {
                        compressOutput = true
                    } else if unprocessedBuf[p + 1] == telnet.dont && unprocessedBuf[p + 2] == telnet.teloptCompress2 {
                        compressOutput = false
                    }
                    // ok, now skip all three symbols:
                    p += 3
                    continue
                // Otherwise, it is a 2-byte sequence unknown to us:
                default:
                    // Skip both IAC and the character after it:
                    p += 2
                    continue
                }
            }
            result.append(unprocessedBuf[p])
            p += 1
        }
        
        let processed = p - from
        unprocessedBuf.removeSubrange(0..<processed)
        
        return result
    }
};

