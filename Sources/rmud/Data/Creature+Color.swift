import Foundation

extension Creature {
    func colorPick(_ fallbackColor: String) -> String {
        if berserkRounds > 0 {
            return Ansi.bRed
        }
        return fallbackColor
    }

    // Normal colors:
    func nNrm() -> String { return colorPick(Ansi.nNrm) }
    func nRed() -> String { return colorPick(Ansi.nRed) }
    func nGrn() -> String { return colorPick(Ansi.nGrn) }
    func nYel() -> String { return colorPick(Ansi.nYel) }
    func nBlu() -> String { return colorPick(Ansi.nBlu) }
    func nMag() -> String { return colorPick(Ansi.nMag) }
    func nCyn() -> String { return colorPick(Ansi.nCyn) }
    func nWht() -> String { return colorPick(Ansi.nRed) }

    // Bold colors:
    func bGra() -> String { return colorPick(Ansi.bGra) }
    func bRed() -> String { return colorPick(Ansi.bRed) }
    func bGrn() -> String { return colorPick(Ansi.bGrn) }
    func bYel() -> String { return colorPick(Ansi.bYel) }
    func bBlu() -> String { return colorPick(Ansi.bBlu) }
    func bMag() -> String { return colorPick(Ansi.bMag) }
    func bCyn() -> String { return colorPick(Ansi.bCyn) }
    func bWht() -> String { return colorPick(Ansi.bWht) }
}

