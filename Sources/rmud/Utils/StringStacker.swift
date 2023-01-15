import Foundation

class StringStacker {
    private class UniqueLine {
        var line: String
        var repeatCount: Int
        
        init(line: String, repeatCount: Int) {
            self.line = line
            self.repeatCount = repeatCount
        }
    }
    
    private typealias StringsAndRepeatCounts = (String, Int)
    private var stringsForTargets: [Creature: [UniqueLine]] = [:]
    
    func collect(target: Creature, line: String) {
        var strings = stringsForTargets[target] ?? []
        
        if let last = strings.last, last.line == line {
            last.repeatCount += 1
        } else {
            strings.append(UniqueLine(line: line, repeatCount: 0))
        }
        
        stringsForTargets[target] = strings
    }
    
    func send() {
        for (target, uniqueLines) in stringsForTargets {
            for uniqueLine in uniqueLines {
                let line = uniqueLine.line
                let repeatCount = uniqueLine.repeatCount
                if repeatCount == 0 {
                    target.send(line)
                } else {
                    target.send("\(line) [\(repeatCount + 1)]")
                }
            }
        }
        stringsForTargets.removeAll(keepingCapacity: true)
    }
}
