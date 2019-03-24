import Foundation
import WebSocket

enum ProcessCommandlineResult {
    case continueGameBoot
    case exitSuccess
    case exitError
}

func main() -> Int32 {
    setlocale(LC_ALL, "")

    switch processCommandline() {
    case .exitSuccess: return 0
    case .exitError: return 1
    case .continueGameBoot: break
    }
    
    if settings.mudPorts.isEmpty {
        settings.mudPorts = [settings.defaultPort]
    }
    
    log("RMUD starting")
    
    //let roomsFilename = filenames.areaFilename(forAreaName: "утеха", fileExtension: "rooms")
    //try? FileManager.default.removeItem(atPath: roomsFilename)

    let path = FileManager.default.currentDirectoryPath
    log("Working directory: \(path)")

    let portsEnding = settings.mudPorts.count > 1 ? "s" : ""
    let portsString = settings.mudPorts.map { String($0) }.joined(separator: ", ")
    log("Parameters: port\(portsEnding) \(portsString); data dir \(filenames.dataPrefix), game dir \(filenames.livePrefix)")

    // Create an EventLoopGroup with an appropriate number
    // of threads for the system we are running on.
    let group = MultiThreadedEventLoopGroup(numThreads: System.coreCount)
    // Make sure to shutdown the group when the application exits.
    defer { try! group.syncShutdownGracefully() }

    log("Setting up signal handlers")
    setupSignalHandlers(on: group)
    
    log("Opening mother sockets")
    networking.setupMotherSockets(ports: settings.mudPorts)
    defer { networking.closeMotherSockets() }

    do {
        try BenchmarkTimer.measure("Boot total time") {
            try db.boot()
        }
    } catch {
        log(error: error)
        return 1
    }

    if settings.saveAreasAfterLoad {
        log("Will save areas and exit")
        BenchmarkTimer.measure() {
            for lowercasedName in db.areaPrototypesByLowercasedName.keys {
                db.save(areaNamed: lowercasedName, prototype: db.areaPrototypesByLowercasedName[lowercasedName]!)
            }
        }
        return 0
    }
    
    log("Setting up websocket server")
    do {
        let _ /*httpServer*/ = try networking.setupHttpServer(on: group)
    } catch {
        log(error: error)
        return 1
    }
    
    log("Entering game loop");
    
    gameLoop()
        
    dispatchMain()
    // Wait for the server to close (indefinitely).
//    do {
//        try httpServer.onClose.wait()
//    } catch {
//        log(error: error)
//        return 1
//    }
//    return 0
}

private func shutdownGame() {
    log("Game stopped")
    //mudShutdown = true
    exit(1)
}

private func processCommandline() -> ProcessCommandlineResult {
    var index = 1
    let argumentsCount = CommandLine.arguments.count
    while index < argumentsCount {
        defer {index += 1 }
        
        let argument = CommandLine.arguments[index]
        guard argument.hasPrefix("-") else {
            log("Arguments should start with '-'")
            return .exitError
        }
        switch argument.suffix(argument.count - 1).lowercased() {
        case "p", "-port":
            guard index < argumentsCount - 1 else {
                log("Please specify a port number, for example: -p \(settings.defaultPort).");
                return .exitError
            }
            guard let port = UInt16(CommandLine.arguments[index + 1]) else {
                log("Please specify a port number in range 0-65535.")
                return .exitError
            }
            index += 1
            settings.mudPorts.append(port)
        case "m", "-mailserver":
            guard index < argumentsCount - 3 else {
                log("Please specify email, mail server and password, for example: no-reply@rmud.org smtp.gmail.com password");
                return .exitError
            }
            settings.accountVerificationEmail = CommandLine.arguments[index + 1]
            settings.mailServer = CommandLine.arguments[index + 2]
            settings.mailServerPassword = CommandLine.arguments[index + 3]
            index += 3
        case "-pwipe":
            settings.isPwipeMode = true
        case "-no-atomic-writes":
            settings.saveFilesAtomically = false
        case "-transliterate-logs":
            settings.transliterateLogs = true
        case "-dump-area-format":
            let filename = filenames.areaFormat
            do {
                log("Preparing area format definitions:")
                try db.registerDefinitions()
                log("Saving area format definitions to: \(filename)")
                try db.definitions.dumpToFile(named: filename)
            } catch {
                log(error: error)
                return .exitError
            }
            return .exitSuccess
        case "-save-maps":
            settings.debugSaveMaps = true
        case "-save-rendered-maps":
            settings.debugSaveRenderedMaps = true
        case "-save-digging-steps":
            settings.debugSaveMapDiggingSteps = true
        case "-log-skipped-rooms":
            settings.debugSaveRoomAlreadyExistsSteps = true
        case "-log-unused-fields":
            settings.debugLogUnusedEntityFields = true
        case "-log-sent-emails":
            settings.debugLogSendEmailResult = true
        case "-save-areas":
            settings.saveAreasAfterLoad = true
        case "-dump-endings-decompress":
            settings.debugDumpEndingsDecompress = true
        case "-dump-endings-compress":
            settings.debugDumpEndingsCompress = true
        case "-fatal-warnings":
            settings.fatalWarnings = true
        case "h", "-help":
            print("""
                Usage: rmud [keys]
                  -h --help                    This help
                  -p --port <port>             Port number, \(settings.defaultPort) by default.
                                               Can be specified multiple times.
                  -m --mailserver              <email> <smtp address> <password>
                                               Mail server parameters, for example:
                                               no-reply@rmud.org smtp.gmail.com password
                     --pwipe                   Allow starting with empty players directory.
                     --no-atomic-writes        Workaround for docker-toolbox filesystem bug
                     --transliterate-logs      Transliterate words to English in logs
                     --dump-area-format        Save areaformat.txt to rmud-debug/
                     --save-maps               Save maps to rmud-debug/maps/
                     --save-rendered-maps      Save rendered maps to rmud-debug/maps/
                     --save-digging-steps      Save map digging steps to rmud-debug/maps/
                     --log-skipped-rooms       Log skipped rooms when digging
                     --log-unused-fields       Log unused entity fields
                     --log-sent-emails         Log validation code emails
                     --fatal-warnings          Quit on warnings
                
                     --save-areas              Resave all areas and quit
                     --dump-endings-decompress Dump endings during decompressing stage
                     --dump-endings-compress   Dump endings during compressing stage
                On exit returns:
                  0                      Normal termination
                  1                      Error has occured
                  2                      Shutdown requested (do not restart)
                  128+signal             Exit on signal (crashed etc)
                
                Не реализованы:
                  -d -data <каталог>     имя каталога с данными, по умолчанию \(filenames.dataPrefix)
                  -i -live <каталог>     имя каталога с рантайм информацией, по умолчанию \(filenames.livePrefix)
                  -l -log <файл>         имя файла журнала, по умолчанию \(filenames.log). '-' - консоль
                  -r -restrict <уровень> ограничение уровня входа в игру, по умолчанию 0
                  -v -verbose            режим подробного ведения журнала
                  -s -scripts            режим отладки скриптов
                  -e -encoding           log encoding: UTF-8, CP1251 etc
                  <имя>                  вызов служебной функции с именем:
                                         syntax       проверка синтаксиса
                """)
            exit(1)
        default:
            log("Unknown argument: \(argument)")
            return .exitError
        }
    }
    return .continueGameBoot
}

func setupSignalHandlers(on eventLoopGroup: MultiThreadedEventLoopGroup) {
    let signalQueue = DispatchQueue(label: "org.rmud.SignalHandlingQueue")
    let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalQueue)
    signalSource.setEventHandler {
        signalSource.cancel()
        log("Received SIGINT: terminating")
        //isTerminated.value = true
        shutdownGame()
    }
    signal(SIGINT, SIG_IGN)
    signalSource.resume()
}

exit(main())
