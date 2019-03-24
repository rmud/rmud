import Foundation

// Файл формата:
// ------
// ; комментарий
// СЕКЦИЯ
// данные
//
// ; комментарий
// СЕКЦИЯ
// данные
// ------
// Секции разделены пустыми строками.
// Секции, состоящие из одних только комментариев игнорируются.
class MutliSectionInfoFileParser {
    private enum State {
        case getSectionName
        case getSectionData
    }
    
    let filename: String
    
    private var state: State = .getSectionName
    private var sectionName = ""
    private var sectionLines = [String]()
    private var dataBySection = [(section: String, lines: [String])]()
    
    init(filename: String) {
        self.filename = filename
    }
    
    func parse() throws -> [(section: String, lines: [String])] {
        let data = try String(contentsOfFile: filename, encoding: .utf8)

        data.forEachLine { line, stop in
            switch state {
            case .getSectionName:
                let processed = trimCommentsAndSpacing(in: line, commentStart: ";")
                if processed.isEmpty { return }
                sectionName = processed
                state = .getSectionData
            case .getSectionData:
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    // End of section
                    closeSection()
                    return
                }
                let processed = trimCommentsAndSpacing(in: line, commentStart: ";")
                if !processed.isEmpty {
                    sectionLines.append(processed)
                }
            }
        }
        closeSection()
        return dataBySection
    }
    
    private func closeSection() {
        guard state == .getSectionData else { return }
 
        dataBySection.append((section: sectionName, lines: sectionLines))
        
        sectionName = ""
        sectionLines.removeAll()
        state = .getSectionName
    }
}
