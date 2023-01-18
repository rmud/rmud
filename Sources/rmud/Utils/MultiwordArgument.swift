import Foundation

struct MultiwordArgument {
    private(set) var full = ""
    private(set) var words: [String] = []
    
    var isEmpty: Bool { return words.isEmpty }
    
    init() {}
    
    init(dotSeparatedWords: String?) {
        guard let dotSeparatedWords = dotSeparatedWords else { return }
        full = dotSeparatedWords

        let maxElements = 10
        words = dotSeparatedWords
            .split(separator: ".", maxSplits: maxElements, omittingEmptySubsequences: true)
            .map(String.init)

        let length = words.count
        guard length > 0 else {
            words.removeAll()
            return;
        }
        guard length < maxElements + 1 else {
            words.removeAll()
            return
        }
    }
}

extension MultiwordArgument: CustomStringConvertible {
    var description: String {
        return full
    }
}
