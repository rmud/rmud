import Foundation

extension Creature {
    func sendStat(
        _ stat: StatInfo,
        indent: Int = 2,
        terminator: String = "\n"
    ) {
        let indentString = String(repeating: " ", count: indent)
        send(
            indentString + stat.description(for: self, indent: indent),
            terminator: terminator
        )
    }
    
    func sendStatGroup(
        _ stats: [StatInfo],
        indent: Int = 2,
        terminator: String = "\n"
    ) {
        let strings = stats.map { stat in
            stat.description(for: self, indent: indent)
        }
        let indentString = String(repeating: " ", count: indent)
        send(
            indentString + strings.joined(separator: " : "),
            terminator: terminator
        )
    }
}
