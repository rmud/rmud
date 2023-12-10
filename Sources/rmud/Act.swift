import Foundation

struct ActFlags: OptionSet {
    typealias T = ActFlags
    
    let rawValue: UInt8

    static let toRoom = T(rawValue: 1 << 0)
    static let toSleeping = T(rawValue: 1 << 1)
    static let dontCapitalize = T(rawValue: 1 << 2)
}

enum ActArgument {
    case text(String)
    case number(Int)
    case to(Creature)
    case excluding(Creature)
    case item(Item)
}

private enum State {
    case searchToken
    case searchIndex
    case searchVisibility
    case searchExtraData
    case captureAnsiColor
}

private enum TokenType {
    case partOfFormatString
    case color
    case text
    case number
    case creature
    case item
}

private enum TokenVisibility {
    case unaffectedByThisObject
    case and
    case or
}

private enum TokenExtraData {
    case none
    case character(Character)
    case stringList([String])
    case text(String)
}

// Tokens have the following form:
// $1и $1(x,y,z) 1и 1(x,y,z)
// type: $, @  (if not specified, it's $)
private struct Token {
    var type: TokenType
    var visibility: TokenVisibility = .unaffectedByThisObject
    var index = 1
    var extraData: TokenExtraData = .none
    var capitalize = false
    
    init(type: TokenType) {
        self.type = type
    }
}

func act(_ text: String, _ flags: ActFlags, _ args: [ActArgument], completion: (_ target: Creature, _ output: String)->()) {
    guard !text.isEmpty else { return }
    
    let tokens = tokenize(text: text, flags: flags)
    
    let targets = targetCreatures(from: args, flags: flags)
    
    for target in targets {
        let output = render(tokens, for: target, with: args)
        completion(target, output)
        //target.send(output)
    }
}

func act(_ text: String, _ flags: ActFlags, _ args: ActArgument..., completion: (_ target: Creature, _ output: String)->()) {
    act(text, flags, args, completion: completion)
}

func act(_ text: String, _ args: ActArgument..., completion: (_ target: Creature, _ output: String)->()) {
    act(text, ActFlags(), args, completion: completion)
}

func act(_ text: String, _ flags: ActFlags, _ args: [ActArgument]) {
    act(text, flags, args) { target, output in
        // Note that if text is empty, this closure won't be called, so no extra check is needed
        target.send(output)
    }
}

func act(_ text: String, _ flags: ActFlags, _ args: ActArgument...) {
    act(text, flags, args)
}
    
func act(_ text: String, _ args: ActArgument...) {
    act(text, ActFlags(), args)
}

private func targetCreatures(from args: [ActArgument], flags: ActFlags) -> Set<Creature> {
    var targets: Set<Creature> = []
    
    if flags.contains(.toRoom) {
        if let creature = findFirstCreature(in: args) {
            for target in creature.inRoom?.creatures ?? [] {
                targets.insert(target)
            }
        }
    }
    
    // First exclude creatures we don't want to send anything to
    for arg in args {
        if case .excluding(let creature) = arg {
            targets.remove(creature)
        }
    }
    
    // Then include explicitly requested ones
    for arg in args {
        if case .to(let creature) = arg {
            targets.insert(creature)
        }
    }

    return targets
}

private func tokenize(text: String, flags: ActFlags) -> [Token] {
    var result: [Token] = []
    
    var token = Token(type: .partOfFormatString)
    token.capitalize = flags.contains(.dontCapitalize) ? false : true

    var state: State = .searchToken
    var capitalizeNextLetter = false
    
    var output = ""
    let flushOutput = {
        if !output.isEmpty {
            token.extraData = .text(output)
            result.append(token)

            token = Token(type: .partOfFormatString)
            token.capitalize = capitalizeNextLetter

            output.removeAll()
            capitalizeNextLetter = false
        }
    }

    var remainingCharacters = text.makeIterator()
    
    var retry = false
    var c: Character = "\0"
    while true {
        if !retry {
            guard let nextC = remainingCharacters.next() else {
                break
            }
            c = nextC
        } else {
            // Otherwise just process `c` again
            retry = false
        }
        
        switch state {
        case .searchToken:
            if c == Ansi.sequenceStart {
                flushOutput()
                token.type = .color
                state = .captureAnsiColor
                output.append(c)
            } else if c == "&" {
                flushOutput()
                token.type = .text
                state = .searchIndex
            } else if c == "#" {
                flushOutput()
                token.type = .number
                state = .searchIndex
            } else if "123456789".contains(String(c)) {
                flushOutput()
                // It's shortcut for '$' (which is no longer used anyway)
                token.type = .creature
                state = .searchIndex
                retry = true
            } else if c == "@" {
                flushOutput()
                token.type = .item
                state = .searchIndex
            } else {
                if c.isLetter {
                    if capitalizeNextLetter {
                        // New sentence will be a new token with capitalized text
                        flushOutput()
                    }
                } else {
                    if capitalizeNextLetter {
                        if !c.isWhitespace && !c.isNewline {
                            capitalizeNextLetter = false
                        }
                    } else {
                        if c.shouldCapitalizeNextLetter {
                            capitalizeNextLetter = true
                        }
                    }
                }
                output.append(c)
            }
        case .searchIndex:
            let s = String(c)
            if let scalar = s.unicodeScalars.first,
                CharacterSet.decimalDigits.contains(scalar) {
                token.index = Int(s) ?? 1
            } else {
                // Index may be absent, in this case this token points
                // to first argument, i.e. #(a,b,c) is a shortcut for #1(a,b,c)
                token.index = 1
                retry = true
            }
            
            if token.type == .creature {
                state = .searchVisibility
            } else if token.type == .text {
                // No modifiers in text tokens, just register this token and reset parsing
                result.append(token)
                token = Token(type: .partOfFormatString)
                state = .searchToken
            } else {
                state = .searchExtraData
            }
        case .searchVisibility:
            if c == "*" {
                token.visibility = .and
            } else if c == "+" {
                token.visibility = .or
            } else {
                // Visibility rules are optional, it's normal not to have them
                retry = true
            }
            state = .searchExtraData
        case .searchExtraData:
            if c == "(" {
                // StringList
                if let stringList = fetchStringList(&remainingCharacters) {
                    token.extraData = .stringList(stringList)
                } else {
                    output += "(ошибка:список)"
                    break
                }
            } else if case let s = String(c),
                let scalar = s.unicodeScalars.first,
                CharacterSet.letters.contains(scalar) {
                // Character
                token.extraData = .character(c)
            } else {
                // Any other character means it doesn't belong to this token
                retry = true
            }
            result.append(token)
            
            token = Token(type: .partOfFormatString)
            state = .searchToken
        case .captureAnsiColor:
            output.append(c)
            if c == Ansi.sequenceEnd {
                let capitalize = token.capitalize
                token.capitalize = false // no effect on color codes
                token.extraData = .text(output)
                result.append(token)

                output.removeAll(keepingCapacity: true)
            
                token = Token(type: .partOfFormatString)
                token.capitalize = capitalize // pass to next token
                state = .searchToken
            }
        }
    }
    
    flushOutput()
    
    if token.type != .partOfFormatString {
        result.append(token)
    }

    return result
}

private func findFirstCreature(in args: [ActArgument]) -> Creature? {
    for arg in args {
        switch arg {
        case .to(let creature): return creature
        case .excluding(let creature): return creature
        default: break
        }
    }
    return nil
}

private func findTextArgument(atIndex index: Int, in args: [ActArgument]) -> String? {
    var atIndex = 1
    for arg in args {
        guard case .text(let string) = arg else { continue }
        guard atIndex == index else {
            atIndex += 1
            continue
        }
        return string
    }
    return nil
}

private func findNumberArgument(atIndex index: Int, in args: [ActArgument]) -> Int? {
    var atIndex = 1
    for arg in args {
        guard case .number(let number) = arg else { continue }
        guard atIndex == index else {
            atIndex += 1
            continue
        }
        return number
    }
    return nil
}

private func findCreatureArgument(atIndex index: Int, in args: [ActArgument]) -> Creature? {
    var atIndex = 1
    for arg in args {
        var found: Creature!
        switch arg {
        case .to(let creature),
             .excluding(let creature):
            found = creature
            break
        default:
            continue
        }
        guard atIndex == index else {
            atIndex += 1
            continue
        }
        return found
    }
    return nil
}

private func findItemArgument(atIndex index: Int, in args: [ActArgument]) -> Item? {
    var atIndex = 1
    for arg in args {
        var found: Item!
        switch arg {
        case .item(let item):
            found = item
            break
        default:
            continue
        }
        guard atIndex == index else {
            atIndex += 1
            continue
        }
        return found
    }
    return nil
}

private func fetchStringList(_ remainingCharacters: inout String.Iterator) -> [String]? {
    var result: [String] = []
    var currentElement = ""
    
    while let c = remainingCharacters.next() {
        switch c {
        case ",":
            result.append(currentElement)
            currentElement.removeAll()
        case ")":
            result.append(currentElement)
            return result
        default:
            currentElement.append(c)
        }
    }
    
    return nil
}

private func render(_ tokens: [Token], for target: Creature, with args: [ActArgument]) -> String {
    // FIXME: canSee for creature and item
    var result = ""
    var output = ""
    for token in tokens {
        defer {
            result += token.capitalize ? output.capitalizingFirstLetter() : output
            output.removeAll(keepingCapacity: true)
        }

        switch token.type {
        case .partOfFormatString, .color:
            if case .text(let string) = token.extraData {
                output = string
            } else {
                assertionFailure()
            }
        case .text:
            guard let text = findTextArgument(atIndex: token.index, in: args) else {
                output = "(ошибка:индекс)"
                continue
            }
            output = text
        case .number:
            guard let number = findNumberArgument(atIndex: token.index, in: args) else {
                output = "(ошибка:индекс)"
                continue
            }
            switch token.extraData {
            case .none:
                output = String(number)
            case .stringList(let endings):
                let ending1 = endings[validating: 0] ?? ""
                let ending2 = endings[validating: 1] ?? ""
                let ending3 = endings[validating: 2] ?? ""
                output = number.ending(ending1, ending2, ending3)
            default:
                output = "(ошибка:формат)"
            }
        case .creature:
            guard let creature = findCreatureArgument(atIndex: token.index, in: args) else {
                output = "(ошибка:индекс)"
                continue
            }
            switch token.extraData {
            case .character(let c):
                switch c {
                case "и": output = creature.nameNominative.full
                case "р": output = creature.nameGenitive.full
                case "д": output = creature.nameDative.full
                case "в": output = creature.nameAccusative.full
                case "т": output = creature.nameInstrumental.full
                case "п": output = creature.namePrepositional.full
                default: output = "(ошибка:формат)"
                }
            case .stringList(let strings):
                switch creature.gender { // FIXME: visible/invisible
                case .masculine:
                    if strings.indices.contains(0) { output = strings[0] }
                case .feminine:
                    if strings.indices.contains(1) { output = strings[1] }
                case .neuter:
                    if strings.indices.contains(2) { output = strings[2] }
                case .plural:
                    if strings.indices.contains(3) { output = strings[3] }
                }
            default: output = "(ошибка:формат)"
            }
        case .item:
            // FIXME: not fully implemented
            guard let item = findItemArgument(atIndex: token.index, in: args) else {
                output = "(ошибка:индекс)"
                continue
            }
            switch token.extraData {
            case .character(let c):
                switch c {
                case "и": output = item.nameNominative.full
                case "р": output = item.nameGenitive.full
                case "д": output = item.nameDative.full
                case "в": output = item.nameAccusative.full
                case "т": output = item.nameInstrumental.full
                case "п": output = item.namePrepositional.full
                default: output = "(ошибка:формат)"
                }
            case .stringList(let strings):
                switch item.gender { // FIXME: visible/invisible
                case .masculine:
                    if strings.indices.contains(0) { output = strings[0] }
                case .feminine:
                    if strings.indices.contains(1) { output = strings[1] }
                case .neuter:
                    if strings.indices.contains(2) { output = strings[2] }
                case .plural:
                    if strings.indices.contains(3) { output = strings[3] }
                }
            default: output = "(ошибка:формат)"
            }
        }
    }
    return result
}
