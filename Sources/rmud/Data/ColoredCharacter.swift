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
    public init(_ string: String, _ color: String = Ansi.nNrm) {
        self = string.map { ColoredCharacter($0, color) }
    }

    public func trimmedRight() -> Self {
        reversed().drop(while: { c in c.character.isWhitespace }).reversed()
    }

    public func rightExpandingTo(_ length: Int, withPad pad: ColoredCharacter) -> [ColoredCharacter] {
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
    public func trimmedRight() -> Self {
        map { row in row.trimmedRight() }
    }
    
    public func appendingRight(
        _ second: [[ColoredCharacter]],
        separator: ColoredCharacter = .init(extendedGraphemeClusterLiteral: " ")
    ) -> [[ColoredCharacter]] {
        return zip(self, second).map { (left, right) -> [ColoredCharacter] in
            var result: [ColoredCharacter] = left
            result.append(separator)
            result += right
            return result
        }
    }

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
