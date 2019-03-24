import Foundation

public struct ColoredCharacter: ExpressibleByExtendedGraphemeClusterLiteral {
    
    public var character: Character
    public var color: String = Ansi.nNrm
    
    public init(extendedGraphemeClusterLiteral value: Character) {
        character = value
    }
    
    init(_ c: Character, _ color: String) {
        character = c
        self.color = color
    }
}

extension ColoredCharacter: Equatable {
    public static func ==(lhs: ColoredCharacter, rhs: ColoredCharacter) -> Bool {
        return lhs.character == rhs.character &&
            lhs.color == rhs.color
    }
}

extension Array where Element == ColoredCharacter {
    public init(_ string: String) {
        self = string.map { ColoredCharacter(extendedGraphemeClusterLiteral: $0) }
    }

    public func padding(toLength length: Int, withPad pad: ColoredCharacter) -> [ColoredCharacter] {
        var result: [ColoredCharacter] = self
        let delta = length - result.count
        if delta > 0 {
            for _ in 0 ..< delta {
                result.append(pad)
            }
        }
        return result
    }
}

extension Array where Element == Array<ColoredCharacter> {
    public func renderedAsString(withColor: Bool) -> String {
        var lastColor = Ansi.nNrm
        let renderedLines: [String]
        if withColor {
            renderedLines = map { coloredCharacters in
                var line = ""
                for c in coloredCharacters {
                    if lastColor != c.color {
                        line += c.color
                        lastColor = c.color
                    }
                    line.append(c.character)
                }
                return line
            }
        } else {
            renderedLines = map { coloredCharacters in
                var line = ""
                for c in coloredCharacters {
                    line.append(c.character)
                }
                return line
            }
        }
        var result = renderedLines.joined(separator: "\n")
        if lastColor != Ansi.nNrm {
            result += Ansi.nNrm
        }
        return result
    }
}
