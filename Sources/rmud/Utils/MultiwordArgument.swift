import Foundation

struct MultiwordArgument {
    private(set) var words: [String] = []
    
    var isEmpty: Bool { return words.isEmpty }
    
    init() {}
    
    init(dotSeparatedWords: String?) {
        guard let dotSeparatedWords = dotSeparatedWords else { return }

        let maxElements = 10
        words = dotSeparatedWords.split(separator: ".", maxSplits: maxElements, omittingEmptySubsequences: true).map(String.init)

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
