import Foundation

class Ansi {
    // No color:
    static let nul = ""

    // Default terminal color (usually 'black on white' or 'white on black')
    static let nNrm = "\u{1B}[0;0m"
    
    // Normal colors:
    static let nBlk = "\u{1B}[0;30m" // may be invisible on some terminals
    static let nRed = "\u{1B}[0;31m"
    static let nGrn = "\u{1B}[0;32m"
    static let nYel = "\u{1B}[0;33m"
    static let nBlu = "\u{1B}[0;34m"
    static let nMag = "\u{1B}[0;35m"
    static let nCyn = "\u{1B}[0;36m"
    static let nWht = "\u{1B}[0;37m"

    // Bold colors:
    static let bGra = "\u{1B}[1;30m" // FIXME: not really bold nor gray on "scan" command
    static let bRed = "\u{1B}[1;31m"
    static let bGrn = "\u{1B}[1;32m"
    static let bYel = "\u{1B}[1;33m"
    static let bBlu = "\u{1B}[1;34m"
    static let bMag = "\u{1B}[1;35m"
    static let bCyn = "\u{1B}[1;36m"
    static let bWht = "\u{1B}[1;37m" // FIXME: maybe invisible on white background?
}

