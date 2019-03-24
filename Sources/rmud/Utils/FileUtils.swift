import Foundation

typealias FileEnumerationHandler = (_ filename: String, _ stop: inout Bool) throws -> ()

struct FileEnumerationFlags: OptionSet {
    typealias T = FileEnumerationFlags
    
    let rawValue: Int
    
    static let sortAlphabetically = T(rawValue: 1 << 0)
}

// FIXME - некорректно обрабатывает пробелы в ключе
func saveDictionary(_ dictionary: [String: String], toFilename filename: String) throws {
    var out = ""
    for entry in dictionary {
        assert(!entry.key.contains(" "))
        assert(!entry.value.contains("\n"))
        out += entry.key
        out += " "
        out += entry.value
        out += "\n"
    }
    try out.write(toFile: filename, atomically: settings.saveFilesAtomically, encoding: .utf8)
}

// FIXME - некорректно обрабатывает пробелы в ключе
func loadDictionary(fromFilename filename: String) throws -> [String: String] {
    var result = [String: String]()

    let data = try String(contentsOfFile: filename, encoding: .utf8)
    
    data.forEachLine { line, stop in
        let parts = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        assert(parts.count == 2)
        result[parts.first!] = parts.last!
    }
    
    return result
}

func enumerateFiles(atPath path: String, ignoreTemporaryFiles: Bool = true, flags: FileEnumerationFlags = [], handler: FileEnumerationHandler) rethrows {
    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(atPath: path)
    
    let shouldProcess: (_ element: String) -> Bool = { element in
        if ignoreTemporaryFiles {
            guard !element.hasPrefix(".") else { return false }
            guard !element.hasSuffix("~") else { return false }
            guard !element.hasSuffix(".swp") else { return false }
        }
        return true
    }
    
    var stop = false

    if flags.contains(.sortAlphabetically) {
        var filenames: [String] = []
        while let element = enumerator?.nextObject() as? String {
            filenames.append(element)
        }
        for element in filenames.sorted(
                by: {$0.caseInsensitiveCompare($1) == .orderedAscending}) {
            guard shouldProcess(element) else { continue }
            try handler(element, &stop)
            if stop { break }
        }
    } else {
        while let element = enumerator?.nextObject() as? String {
            guard shouldProcess(element) else { continue }
            try handler(element, &stop)
            if stop { break }
        }
    }
}

func enumerateFiles(atPath path: String, withExtension ext: String, flags: FileEnumerationFlags = [], handler: FileEnumerationHandler) rethrows {
    
    let dotExt = "." + ext
    
    try enumerateFiles(atPath: path) { filename, stop in
        guard filename.hasSuffix(dotExt) else { return }
        try handler(filename, &stop)
    }
}

func enumerateFiles(atPath path: String, withExtensions extensions: [String], flags: FileEnumerationFlags = [], handler: FileEnumerationHandler) rethrows {
    
    let dotExtensions = extensions.map { "." + $0 }
    
    try enumerateFiles(atPath: path) { filename, stop in
        for dotExtension in dotExtensions {
            if filename.hasSuffix(dotExtension) {
                try handler(filename, &stop)
                return
            }
        }
    }
}

