import Foundation

public class Ansi {
    // No color:
    public static let nul = ""

    // Default terminal color (usually 'black on white' or 'white on black')
    public static let nNrm = "\u{1B}[0;0m"
    
    // Normal colors:
    public static let nBlk = "\u{1B}[0;30m" // may be invisible on some terminals
    public static let nRed = "\u{1B}[0;31m"
    public static let nGrn = "\u{1B}[0;32m"
    public static let nYel = "\u{1B}[0;33m"
    public static let nBlu = "\u{1B}[0;34m"
    public static let nMag = "\u{1B}[0;35m"
    public static let nCyn = "\u{1B}[0;36m"
    public static let nWht = "\u{1B}[0;37m"

    // Bold colors:
    public static let bGra = "\u{1B}[1;30m" // FIXME: not really bold nor gray on "scan" command
    public static let bRed = "\u{1B}[1;31m"
    public static let bGrn = "\u{1B}[1;32m"
    public static let bYel = "\u{1B}[1;33m"
    public static let bBlu = "\u{1B}[1;34m"
    public static let bMag = "\u{1B}[1;35m"
    public static let bCyn = "\u{1B}[1;36m"
    public static let bWht = "\u{1B}[1;37m" // FIXME: maybe invisible on white background?
}

