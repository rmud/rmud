import Foundation

func structureName(fromFieldName name: String) -> String? {
    guard name.contains(".") else { return nil }
    return name.components(separatedBy: ".").first
}

func structureAndFieldName(_ fullName: String) -> (String, String) {
    guard let range = fullName.range(of: ".") else { return ("", fullName) }
    return (String(fullName.prefix(upTo: range.lowerBound)),
            String(fullName.suffix(from: range.upperBound)))
}

func appendIndex(toName name: String, index: Int) -> String {
    return "\(name)[\(index)]"
}

func removeIndex(fromName name: String) -> (String, Int?) {
    guard let range1 = name.range(of: "[") else { return (name, nil) }
    guard let range2 = name.range(of: "]", range: range1.upperBound..<name.endIndex) else { return (name, nil) }
    let nameWithoutIndex = String(name.prefix(upTo: range1.lowerBound))
    let index = Int(name[range1.upperBound..<range2.lowerBound]) ?? 0
    return (nameWithoutIndex, index)
}

func structureIfNotEmpty(_ name: String, contentGenerator: (_ content: inout String) -> ()) -> String {
    var content = "  \(name) (\n"
    let previousContent = content
    contentGenerator(&content)
    guard content != previousContent else { return "" }
    content += "  )\n"
    return content
}
