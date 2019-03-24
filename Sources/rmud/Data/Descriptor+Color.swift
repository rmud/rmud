import Foundation

extension Descriptor {
    func nNrm() -> String { return hasColor ? Ansi.nNrm : Ansi.nul }

    // Normal colors:
    func nBlk() -> String { return hasColor ? Ansi.nBlk : Ansi.nul }
    func nRed() -> String { return hasColor ? Ansi.nRed : Ansi.nul }
    func nGrn() -> String { return hasColor ? Ansi.nGrn : Ansi.nul }
    func nYel() -> String { return hasColor ? Ansi.nYel : Ansi.nul }
    func nBlu() -> String { return hasColor ? Ansi.nBlu : Ansi.nul }
    func nMag() -> String { return hasColor ? Ansi.nMag : Ansi.nul }
    func nCyn() -> String { return hasColor ? Ansi.nCyn : Ansi.nul }
    func nWht() -> String { return hasColor ? Ansi.nRed : Ansi.nul }
    
    // Bold colors:
    func bGra() -> String { return hasColor ? Ansi.bGra : Ansi.nul }
    func bRed() -> String { return hasColor ? Ansi.bRed : Ansi.nul }
    func bGrn() -> String { return hasColor ? Ansi.bGrn : Ansi.nul }
    func bYel() -> String { return hasColor ? Ansi.bYel : Ansi.nul }
    func bBlu() -> String { return hasColor ? Ansi.bBlu : Ansi.nul }
    func bMag() -> String { return hasColor ? Ansi.bMag : Ansi.nul }
    func bCyn() -> String { return hasColor ? Ansi.bCyn : Ansi.nul }
    func bWht() -> String { return hasColor ? Ansi.bWht : Ansi.nul }
}


