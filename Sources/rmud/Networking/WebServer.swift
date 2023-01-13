import Foundation
import Vapor

class WebServer {
    static let sharedInstance = WebServer()

    func setup() {
        for port in Settings.sharedInstance.wsPorts {
            let vaporQueue = DispatchQueue(label: "rmud.vapor.queue.\(port)")
            vaporQueue.async {
                LoggingSystem.bootstrap { label in
                    return WebLogHandler(label: "Web")
                }

                do {
                    let app = Application()
                    app.http.server.configuration.hostname = "0.0.0.0"
                    app.http.server.configuration.port = Int(port)
                    defer { app.shutdown() }

                    try self.configureApp(app)
                    try app.run()
                } catch {
                    DispatchQueue.main.async {
                        log(error: error)
                    }
                    exit(1)
                }
            }
        }
    }

    private func configureApp(_ app: Application) throws {
        app.webSocket("") { req, ws in
            // This closure will be called with each new WebSocket client
            // WARNING: The upgrade closures may be called on any event loop. Be careful to avoid race conditions if you must access external variables.
            DispatchQueue.main.async {
                newDescriptor(webSocket: ws, httpRequest: req)
            }
            ws.onText { ws, text in
                DispatchQueue.main.async {
                    if let descriptor = networking.descriptors.first(where: { d in
                        if case .webSocket(let webSocket) = d.handle {
                            return webSocket === ws
                        }
                        return false
                    }) {
                        do {
                            if let data = text.data(using: .utf8),
                                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                if let type = json["type"] as? String,
                                        type == "command",
                                        let text = json["text"] as? String {
                                    // FIXME: omitting empty sequences here can interfere with file pasting
                                    // in future, consider moving it to gameLoop()
                                    let commands = text.split(omittingEmptySubsequences: true, whereSeparator: { $0 == "\n" || $0 == "\r\n" })
                                    if !commands.isEmpty {
                                        for command in commands {
                                            descriptor.commandsFromWebSocket.append(String(command))
                                        }
                                    } else {
                                        // Refresh the prompt
                                        descriptor.commandsFromWebSocket.append(String())
                                    }
                                }
                            }
                        } catch {
                            // Ignore malformed data
                        }
                    }
                }
            }
            let _ = ws.onClose.always { _ in
                DispatchQueue.main.async {
                    if let descriptor = networking.descriptors.first(where: { d in
                        if case .webSocket(let webSocket) = d.handle {
                            return webSocket === ws
                        }
                        return false
                    }) {
                        descriptor.closeSocket()
                    }
                }
            }

        }
    }
}

