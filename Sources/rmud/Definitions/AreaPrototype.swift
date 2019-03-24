import Foundation

public class AreaPrototype {
    var lowercasedName: String
    var vnumRange: ClosedRange<Int>

    // The rest are optional
    var comment: [String]
    var description: String?
    var resetCondition: AreaResetCondition?
    var resetInterval: Int?
    var originVnum: Int?
    
    var roomPrototypesByVnum = [Int: RoomPrototype]()
    var mobilePrototypesByVnum = [Int: MobilePrototype]()
    var itemPrototypesByVnum = [Int: ItemPrototype]()
    
    init?(entity: Entity) {
        // MARK: Key fields
        
        // Required:
        guard let name = entity["область"]?.string else {
            assertionFailure()
            return nil
        }
        self.lowercasedName = name.lowercased()

        guard let firstRoom = entity["комнаты.первая", 0]?.int,
            let lastRoom = entity["комнаты.последняя", 0]?.int,
            firstRoom <= lastRoom
        else {
                assertionFailure()
                return nil
        }
        vnumRange = firstRoom...lastRoom

        // MARK: Other optional fields

        comment = entity["комментарий"]?.stringArray ?? []
        description = entity["описание"]?.string // ?? "Без описания"
        resetCondition = entity["сброс.условие", 0]?.uint8.flatMap { AreaResetCondition(rawValue: $0) }
        resetInterval = entity["сброс.период", 0]?.int // ?? 30
        //age = 0
        originVnum = entity["комнаты.основная", 0]?.int
    }

    func save(for style: Value.FormattingStyle, with definitions: Definitions) -> String {
        // MARK: Key fields

        var result = "ОБЛАСТЬ \(Value(line: lowercasedName).formatted(for: style))\n"
        result += structureIfNotEmpty("КОМНАТЫ") { content in
            content += "    ПЕРВАЯ \(Value(number: vnumRange.lowerBound).formatted(for: style))\n"
            content += "    ПОСЛЕДНЯЯ \(Value(number: vnumRange.upperBound).formatted(for: style))\n"
            if let originVnum = originVnum {
                content += "    ОСНОВНАЯ \(Value(number: originVnum).formatted(for: style))\n"
            }
        }
        
        // MARK: Other optional fields

        if let description = description {
            result += "  ОПИСАНИЕ \(Value(line: description).formatted(for: style))\n"
        }
        if !comment.isEmpty {
            result += "  КОММЕНТАРИЙ \(Value(longText: comment).formatted(for: style, continuationIndent: 14))\n"
        }
        result += structureIfNotEmpty("СБРОС") { content in
            if let resetCondition = resetCondition {
                let enumSpec = definitions.enumerations.enumSpecsByAlias["сброс.условие"]
                content += "    УСЛОВИЕ \(Value(enumeration: resetCondition).formatted(for: style, enumSpec: enumSpec))\n"
            }
            if let resetInterval = resetInterval {
                content += "    ПЕРИОД \(Value(number: resetInterval).formatted(for: style))\n"
            }
        }
        return result
    }
}

