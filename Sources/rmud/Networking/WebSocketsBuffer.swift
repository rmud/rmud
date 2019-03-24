import Foundation

//protocol BufferElement: Codable {
//    var type: String { get }
//    var data: Any { get }
//}

class WebSocketsBuffer {
    enum Element {
        case ansiText(AnsiText)
        case streamCommand(StreamCommand)
        
        func encode(with encoder: JSONEncoder) throws -> Data {
            switch self {
            case .ansiText(let ansiText): return try encoder.encode(ansiText)
            case .streamCommand(let streamCommand): return try encoder.encode(streamCommand)
            }
        }
    }
    
    final class AnsiText: Codable {
        let type = "ansiText"
        var text: String
        
        init(text: String) {
            self.text = text
        }
    }
    
    final class StreamCommand: Codable {
        enum Command: String, Codable {
            case echoOff
            case echoOn
        }
        
        let type = "streamCommand"
        var command: Command
        
        init(command: Command) {
            self.command = command
        }
    }

    var elements: [Element] = []
    
    func append(ansiText text: String) {
        if case .ansiText(let ansiText)? = elements.last {
            ansiText.text += text
        } else {
            let ansiText = AnsiText(text: text)
            elements.append(.ansiText(ansiText))
        }
    }
    
    func append(command: StreamCommand.Command) {
        append(element: .streamCommand(StreamCommand(command: command)))
    }
    
    func append(element: Element) {
        elements.append(element)
    }
}
