import Vapor

class WebLogHandler {
    var metadata: Logger.Metadata = Logger.Metadata()
    var logLevel: Logger.Level = .info
    var label: String

    public init(label: String) {
        self.label = label
    }
}

extension WebLogHandler: LogHandler {
    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let metadataFormatted = !(metadata?.isEmpty ?? true) ?
            metadata!.map { "\($0)=\($1)" }.joined(separator: ",") : nil
        
        let text: String
        if let metadataFormatted = metadataFormatted {
            text = "\(self.label) [\(level)] <\(metadataFormatted)> \(message)"
        } else {
            text = "\(self.label) [\(level)] \(message)"
        }

        DispatchQueue.main.async {
            rmud.log(text)
        }
    }

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }
}
