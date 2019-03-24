import Foundation

extension Creature {
    func colorPick(_ descriptorColorChooser: (Descriptor)->String) -> String {
        guard let descriptor = descriptor,
                descriptor.hasColor else {
            return Ansi.nul
        }
        if berserkRounds > 0 {
            return descriptor.bRed()
        }
        return descriptorColorChooser(descriptor)
    }

    // Normal colors:
    func nNrm() -> String { return colorPick { $0.nNrm() } }
    func nRed() -> String { return colorPick { $0.nRed() } }
    func nGrn() -> String { return colorPick { $0.nGrn() } }
    func nYel() -> String { return colorPick { $0.nYel() } }
    func nBlu() -> String { return colorPick { $0.nBlu() } }
    func nMag() -> String { return colorPick { $0.nMag() } }
    func nCyn() -> String { return colorPick { $0.nCyn() } }
    func nWht() -> String { return colorPick { $0.nRed() } }

    // Bold colors:
    func bGra() -> String { return colorPick { $0.bGra() } }
    func bRed() -> String { return colorPick { $0.bRed() } }
    func bGrn() -> String { return colorPick { $0.bGrn() } }
    func bYel() -> String { return colorPick { $0.bYel() } }
    func bBlu() -> String { return colorPick { $0.bBlu() } }
    func bMag() -> String { return colorPick { $0.bMag() } }
    func bCyn() -> String { return colorPick { $0.bCyn() } }
    func bWht() -> String { return colorPick { $0.bWht() } }
}

