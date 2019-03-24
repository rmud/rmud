import Foundation

class Endings {
    typealias FormEndings = [String]
    
    static let sharedInstance = Endings()
    
    var inanimateEndingsByNominativeEnding: [String: FormEndings] = [:]
    var animateEndingsByNominativeEnding: [String: FormEndings] = [:]
    
    var longestInanimateEndings: [FormEndings] = []
    var longestAnimateEndings: [FormEndings] = []

    func decompress(names: String, isAnimate: Bool) -> [String] {
        let (words, separators) = splitToWords(sentence: names)
        var forms: [ [String] ] = Array(repeating: [], count: 6)
        for word in words {
            guard let (endingsFrom, endingsTo, endings) = word.slice(from: "(", to: ")") else {
                forms = forms.map { $0 + [word] }
                continue
            }
            
            // Include "("...")" too:
            let from = word.index(before: endingsFrom)
            let to = word.index(after: endingsTo)
            
            let endingComponents = endings.split(separator: ",", omittingEmptySubsequences: false)
            if endingComponents.count == 1 {
                // Requires table lookup
                let nominativeEnding = String(endingComponents[0])
                if let endings = isAnimate ? animateEndingsByNominativeEnding[nominativeEnding] :
                        inanimateEndingsByNominativeEnding[nominativeEnding] {
                    forms = zip(forms, endings).map {
                        let expanded = word.replacingCharacters(in: from..<to, with: $1)
                        return $0 + [expanded]
                    }
                } else {
                    // Ending not found in table, just duplicate nominativeEnding for every grammar form
                    forms = forms.map {
                        let expanded = word.replacingCharacters(in: from..<to, with: nominativeEnding)
                        return $0 + [expanded]
                    }
                }
            } else {
                // Unrolled ending, just append
                forms = Zip2WithNilPadding(forms, endingComponents).compactMap {
                    let endingComponent: Substring
                    if let component = $1 {
                        endingComponent = (component != "*") ? component : ""
                    } else {
                        endingComponent = ""
                    }
                    guard let words = $0 else { return nil }
                    let expanded = word.replacingCharacters(in: from..<to, with: endingComponent)
                    return words + [expanded]
                }
            }
        }
        let result = forms.map { joinIntoSentence(words: $0, separators: separators) }
        if settings.debugDumpEndingsDecompress {
            print("\(names) -- \(isAnimate ? "🙂 animate" : "☠️ inanimate")")
            for (form, name) in zip(["и", "р", "д", "в", "т", "п"], result) {
                print("  \(form): \(name)")
            }
        }
        return result
    }
    
    func compress(names: [String], isAnimate: Bool) -> String {
        let wordsAndSeparators = names.map { splitToWords(sentence: $0) }
        let forms: [ [String] ] = wordsAndSeparators.map { $0.words }
        var resultingWords: [String] = []
        guard !forms.isEmpty else { return "" }
        let maximumWordCount: Int = forms.map { $0.count }.max() ?? 0

        let possibleEndings = isAnimate ? longestAnimateEndings : longestInanimateEndings
        
        for index in 0..<maximumWordCount {
            let wordForms = forms.map { $0[safe: index].flatMap({ Substring($0) }) }
            if let endings = findLongestEnding(in: wordForms, among: possibleEndings) {
                // Surround ending with brackets
                let nominativeEnding = endings[0]
                var resultingWord: String = String(wordForms[0]?.dropLast(nominativeEnding.count) ?? "")
                resultingWord += "(" + nominativeEnding + ")"
                resultingWords.append(resultingWord)
            } else {
                // Add word as is
                let uniqueElements: Set<Substring> = Set(wordForms.map{($0 ?? "")})
                if uniqueElements.count <= 1 {
                    // All equal
                    if let word = uniqueElements.first {
                        resultingWords.append(String(word))
                    }
                } else {
                    // Forms differ, try dropping common suffix
                    let compactedWordForms = wordForms.compactMap({$0})
                    let commonSuffix = compactedWordForms.longestCommonSuffix()
                    let withoutCommonSuffix = wordForms.map {
                        return $0?.dropLast(commonSuffix.count)
                    }
                    
                    // If remaining part is a known ending, replace it with a short form
                    var resultingWord: String
                    if let endings = findLongestEnding(in: withoutCommonSuffix, among: possibleEndings) {
                        // Surround ending with brackets
                        let nominativeEnding = endings[0]
                        resultingWord = String(withoutCommonSuffix[0]?.dropLast(nominativeEnding.count) ?? "")
                        resultingWord += "(" + nominativeEnding + ")"
                        resultingWord += commonSuffix
                    } else {
                        // Otherwise just list all forms in brackets
                        var prefix = compactedWordForms.longestCommonPrefix()
                        let longestWordLength = compactedWordForms.map { $0.count }.max() ?? 0
                        let maximumPossiblePrefixLength = longestWordLength - commonSuffix.count
                        if prefix.count > maximumPossiblePrefixLength {
                            // Shorten prefix so it won't overlap with suffix
                            prefix = String(prefix.dropLast(prefix.count - maximumPossiblePrefixLength))
                        }
                        let withoutPrefixesAndSuffixes: [String.SubSequence] = withoutCommonSuffix.map {
                            guard let word = $0 else { return "" }
                            return word.dropFirst(prefix.count)
                        }
                        resultingWord = prefix + "(" + withoutPrefixesAndSuffixes.joined(separator: ",") + ")" + commonSuffix
                    }
                    
                    resultingWords.append(resultingWord)
                }
            }
        }
        
        // Use separators from nominative form
        let result = joinIntoSentence(words: resultingWords,
                                      separators: wordsAndSeparators[validating: 0]?.separators ?? [])
        if settings.debugDumpEndingsCompress {
            print("\(result) -- \(isAnimate ? "🙂 animate" : "☠️ inanimate")")
            for (form, name) in zip(["и", "р", "д", "в", "т", "п"], names) {
                print("  \(form): \(name)")
            }
        }
        return result
    }
    
    private func findLongestEnding(in forms: [Substring?], among endings: [FormEndings]) -> FormEndings? {
        let formsCount = 6
        guard forms.count == formsCount else { return nil }
        for endingForms in endings {
            assert(endingForms.count == formsCount)
            // Does nominative form match ending?
            let nominativeForm = forms[0] ?? ""
            let nominativeEnding = endingForms[0]
            guard nominativeForm.hasSuffix(nominativeEnding) else {
                continue
            }
            // If yes, check if other forms match starting from the same offset:
            let endingOffset = nominativeForm.count - nominativeEnding.count
            var otherFormsMatch = true
            for formIndex in 1..<formsCount { // start from 1 to skip nominative form
                let form = (forms[formIndex] ?? "")
                if endingOffset > form.count { // '==' case is ok because it can match an empty string
                    otherFormsMatch = false
                    break
                }
                let index = form.index(form.startIndex, offsetBy: endingOffset)
                let ending = form[index...]
                guard ending == endingForms[formIndex] else {
                    otherFormsMatch = false
                    break
                }
            }
            guard otherFormsMatch else { continue }
            return endingForms
        }
        return nil
    }
    
//    private func hasMatchingEnding(forms: [String.SubSequence], among endings: [FormEndings]) -> Bool {
//        let formsCount = 6
//        guard forms.count == formsCount else { return false }
//        for ending in endings {
//            var allMatch = true
//            for formIndex in 0..<formsCount {
//                guard forms[formIndex] == ending[formIndex] else {
//                    allMatch = false
//                    break
//                }
//            }
//            guard allMatch else { continue }
//            return true
//        }
//        return false
//    }
    
    func load() throws {
        try loadEndings()
        log("  \(inanimateEndingsByNominativeEnding.count) ending\(inanimateEndingsByNominativeEnding.count.ending("", "s", "s"))")
        
        longestInanimateEndings = inanimateEndingsByNominativeEnding.values.sorted {
            let count1 = $0[0].count
            let count2 = $1[0].count
            return count1 < count2 || (count1 == count2 && $0[0] > $1[0])
            }.reversed()
        
        longestAnimateEndings = animateEndingsByNominativeEnding.values.sorted {
            let count1 = $0[0].count
            let count2 = $1[0].count
            return count1 < count2 || (count1 == count2 && $0[0] > $1[0])
            }.reversed()
    }
    
    private func loadEndings() throws {
        let data = try String(contentsOfFile: filenames.endings, encoding: .utf8)
        data.forEachLine { line, stop in
            var withoutComments: Substring = line[...]
            if let index = withoutComments.firstIndex(of: ";") {
                withoutComments = withoutComments[..<index]
            }
            if let index = withoutComments.firstIndex(of: "#") {
                withoutComments = withoutComments[..<index]
            }
            let trimmed = withoutComments.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                return
            }
            let lowercased = trimmed.lowercased()
            var inanimateForms: [String] = []
            var animateForms: [String] = []
            lowercased.components(separatedBy: CharacterSet.whitespaces).filter({ !$0.isEmpty }).enumerated().forEach {
                let inanimateAnimate: [String] = $0.element.split(separator: "-")
                    .map { String($0).replacingOccurrences(of: "*", with: "") }
                switch inanimateAnimate.count {
                case 1:
                    inanimateForms.append(inanimateAnimate[0])
                    animateForms.append(inanimateAnimate[0])
                case 2:
                    inanimateForms.append(inanimateAnimate[0])
                    animateForms.append(inanimateAnimate[1])
                default:
                    fatalError("\(filenames.endings): invalid '-' separated parts count in ending: \(inanimateAnimate)")
                }
            }
            guard inanimateForms.count == 6 && animateForms.count == 6 else {
                fatalError("\(filenames.endings): invalid inanimate/animate forms count: expected 6, got \(inanimateForms.count)/\(animateForms.count)")
            }
            if inanimateEndingsByNominativeEnding[inanimateForms[0]] != nil {
                fatalError("\(filenames.endings): duplicate animate ending: \(inanimateForms[0])")
            }
            inanimateEndingsByNominativeEnding[inanimateForms[0]] = inanimateForms
            if animateEndingsByNominativeEnding[animateForms[0]] != nil {
                fatalError("\(filenames.endings): duplicate inanimate ending: \(inanimateForms[0])")
            }
            animateEndingsByNominativeEnding[animateForms[0]] = animateForms
        }
    }
    
    private func splitToWords(sentence: String) -> (words: [String], separators: [String]) {
        let scanner = Scanner(string: sentence)
        scanner.charactersToBeSkipped = .whitespaces
        
        let dashCharacterSet = CharacterSet(charactersIn: "-")
        let wordSeparatorCharacterSet = CharacterSet.whitespaces.union(dashCharacterSet)
        let wordCharacterSet = wordSeparatorCharacterSet.inverted
        
        var words: [String] = []
        var separators: [String] = []
        var isFirstWord = true
        while !scanner.isAtEnd {
            if isFirstWord {
                isFirstWord = false
            } else {
                if scanner.skipCharacters(from: dashCharacterSet) {
                    separators.append("-")
                } else {
                    separators.append(" ")
                }
            }
            guard let word = scanner.scanCharacters(from: wordCharacterSet) else { continue }
            words.append(word)
        }
        return (words: words, separators: separators)
    }
    
    private func joinIntoSentence(words: [String], separators: [String]) -> String {
        var result = ""
        var isFirstWord = true
        for (index, word) in words.enumerated() {
            if isFirstWord {
                isFirstWord = false
            } else {
                let separator = separators[validating: index - 1] ?? " "
                result += separator
            }
            result += word
        }
        return result
    }
}
