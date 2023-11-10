import Foundation
import Vapor

func gameLoop() {
    var inputSet = fd_set()
    var outputSet = fd_set()
    var excSet = fd_set()
    var lastTime = timeval()
    #if os(Linux)
    let optTime = timeval(tv_sec: 0, tv_usec: __suseconds_t(optUsec))
    #else
    let optTime = timeval(tv_sec: 0, tv_usec: Int32(optUsec))
    #endif
    var beforeSleep = timeval()
    var now = timeval()
    var missedPulses = 0
    
    gettimeofday(&lastTime, nil)
    
    var loopOnce: (()->())?
        
    loopOnce = {
        //guard !mudShutdown else { return }
        
        // Set up the input, output, and exception sets for select()
        inputSet.zero()
        outputSet.zero()
        excSet.zero()
        
        var maxDesc = Networking.invalidSocket
        for curDesc in networking.motherDescs {
            inputSet.set(curDesc)
            if maxDesc == Networking.invalidSocket || curDesc > maxDesc {
                maxDesc = curDesc
            }
        }
        
        for d in networking.descriptors {
            switch d.handle {
            case .socket(let socket):
                if socket > maxDesc {
                    maxDesc = socket
                }
                inputSet.set(socket)
                outputSet.set(socket)
                excSet.set(socket)
            default:
                break
            }
        }

        // At this point, we have completed all input, output and heartbeat
        // activity from the previous iteration, so we have to put ourselves
        // to sleep until the next 0.1 second tick. The first step is to
        // calculate how long we took processing the previous iteration.
        gettimeofday(&beforeSleep, nil)
        var processTime = timediff(beforeSleep, lastTime)
        
        // If we were asleep for more than one pass, count missed pulses and
        // sleep until we're resynchronized with the next upcoming pulse.
        if processTime.tv_sec == 0 && processTime.tv_usec < Int32(optUsec) {
            missedPulses = 0
        } else {
            missedPulses = processTime.tv_sec * passesPerSec
            missedPulses += Int(processTime.tv_usec) / optUsec
            processTime.tv_sec = 0
	    #if os(Linux)
            processTime.tv_usec = __suseconds_t(Int(processTime.tv_usec) % optUsec)
	    #else
            processTime.tv_usec = Int32(Int(processTime.tv_usec) % optUsec)
	    #endif
        }
        
        // Calculate the time we should wake up and keep sleeping until then
        let tempTime = timediff(optTime, processTime)
        lastTime = timeadd(beforeSleep, tempTime)
        gettimeofday(&now, nil)
        let timeout = timediff(lastTime, now)
        
        // Go to sleep
        let deadline: DispatchTime = .now() + .seconds(Int(timeout.tv_sec)) + .microseconds(Int(timeout.tv_usec))
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            // Poll without blocking for new input, output, and exceptions
            if select(maxDesc + 1, &inputSet, &outputSet, &excSet, &nullTime) < 0 {
                logSystemError("Select poll")
                return
            }
            
            // if there are new connections waiting, accept them
            for curDesc in networking.motherDescs {
                if inputSet.isSet(curDesc) {
                    newDescriptor(curDesc)
                }
            }
            
            // Kick out the freaky folks in the exception set
            for d in networking.descriptors {
                switch d.handle {
                case .socket(let socket):
                    if excSet.isSet(socket) {
                        inputSet.clear(socket)
                        outputSet.clear(socket)
                        d.closeSocket()
                    }
                default:
                    break
                }
            }
            
            // Process descriptors with input pending
            // Read data from sockets and fill player's command queue
            processPendingInput(inputSet: &inputSet)
            
            // Process commands we just read from process_input
            for d in networking.descriptors {
                if !d.inBuf.isEmpty {
                    d.fetchCommandsFromInput()
                }
                
                // Skip if no input
                let command: String
                switch d.handle {
                case .socket:
                    if d.commandsInSourceEncoding.isEmpty {
                        continue
                    }
                    let commandInSourceEncoding = d.commandsInSourceEncoding.first!
                    var commandBuf = d.convertEncodingToMud(commandInSourceEncoding)
                    commandBuf.append(0)
                    command = String(cString: commandBuf)
                    d.commandsInSourceEncoding.removeFirst()
                case .webSocket:
                    if d.commandsFromWebSocket.isEmpty {
                        continue
                    }
                    command = d.commandsFromWebSocket.removeFirst()
                    let textToSend: String
                    if !command.isEmpty {
                        textToSend = d.isEchoOn ? command : "<скрыто>"
                    } else {
                        textToSend = "⏎"
                    }
                    d.sendAmendingPromptToAllDescriptors(textToSend)
                }
                
                d.isAtPrompt = false // user pressed CR and moved to newline
                
                d.idleTicsAtPrompt = 0
                
                if d.state != .playing {
                    nanny(d, line: command)
                    if d.state != .playing {
                        sendStatePrompt(d)
                    }
                } else {
                    d.creature?.interpretCommand(command)
                }
            }
            
            scheduler.runEvents()
            
            // Send prompts to players who are currently not on prompt:
            for d in networking.descriptors {
                if !d.isAtPrompt && d.state == .playing {
                    guard let creature = d.creature else { continue }
                    guard !(d.creature?.runtimeFlags.contains(.suppressPrompt) ?? false) else { continue }
                    let prompt = creature.makePrompt()

                    d.sendPrompt(prompt)
                }
            }
            
            // Send queued output out to the operating system
            sendQueuedOutput(outputSet: &outputSet)
            
            networking.closeClosedDescriptors()

            if missedPulses < 0 {
                log("WARNING: missed pulses count is negative (\(missedPulses)).")
                logToMud("ВНИМАНИЕ: ЧИСЛО ПРОПУЩЕННЫХ ПУЛЬСОВ ОТРИЦАТЕЛЬНОЕ (\(missedPulses)), " +
                    "ВРЕМЯ ИДЕТ В ОБРАТНОМ НАПРАВЛЕНИИ!",
                    verbosity: .normal)
                missedPulses = 0
            } else if missedPulses >= passesPerSec {
                let missedSeconds = missedPulses / passesPerSec
                let endingEng = missedSeconds == 1 ? "" : "s"
                let ending1 = missedSeconds.ending("а", "о", "о")
                let ending2 = missedSeconds.ending("а", "ы", "")
                log("WARNING: missed \(missedSeconds) second\(endingEng) of game pulses.")
                logToMud("ВНИМАНИЕ: пропущен\(ending1) \(missedSeconds) секунд\(ending2) игровых пульсов.",
                    verbosity: .normal)
                missedPulses = 0 // We missed too many pulses, forget it
            }

            
            // Now, we execute as many pulses as necessary: just one if we haven't
            // missed any pulses, or make up for lost time if we missed a few
            // pulses by sleeping for too long.
            // FIXME: this looks wrong, what about executing player's commands etc?
            missedPulses += 1
            while missedPulses > 0 {
                gameTime.gamePulse += 1
                do {
                    try heartbeat()
                } catch {
                    log("ERROR: \(error.userFriendlyDescription)".capitalizingFirstLetter())
                    log("Game stopped");
                    exit(1)
                }
                missedPulses -= 1
            }
            DispatchQueue.main.async { loopOnce?() }
        }
    }
    loopOnce?()
}

// Sets the kernel's send buffer size for the descriptor
private func newDescriptor(_ s: Networking.Socket) {
    // Accept the new connection
    var peerIn = sockaddr_in()
    var li = socklen_t(MemoryLayout.stride(ofValue: peerIn))
    let desc = withUnsafeMutablePointer(to: &peerIn) { saInPtr in
        saInPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
            accept(s, saPtr, &li)
        }
    }
    if desc == Networking.invalidSocket {
        logSystemError("accept")
        return
    }
    
    // Keep it from blocking
    networking.nonBlock(desc)
    
    /* Set the send buffer size */
    if !networking.setSendBuf(desc, Int32(Networking.maxOutBufSize)) {
        networking.closeSocket(desc)
        return
    }
    
    guard checkMaximumPlayers() else {
        networking.closeSocket(desc)
        return
    }
    
    let (ip, hostname) = dns.dnsResolve(peerIn)
    
    // Create a new descriptor
    prepareDescriptorAndLogConnection(ip: ip, hostname: hostname, handle: .socket(desc))
}

func newDescriptor(webSocket: WebSocket, httpRequest: Request) {
    guard checkMaximumPlayers() else {
        let _ = webSocket.close()
        return
    }

    var ip = ""
    var hostname = ""
    httpRequest.peerAddress?.withSockAddr { sockaddr, size in
        sockaddr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { sockaddr_in in
            (ip, hostname) = dns.dnsResolve(sockaddr_in.pointee)
        }
    }
    
    prepareDescriptorAndLogConnection(ip: ip, hostname: hostname,  handle: .webSocket(webSocket))
}

private func checkMaximumPlayers() -> Bool {
    // Make sure we have room for it */
    let socketsConnected = networking.descriptors.count
    
    if socketsConnected >= settings.maxPlayers {
        return false
    }

    return true
}

private func prepareDescriptorAndLogConnection(ip: String, hostname: String, handle: Descriptor.Handle) {
    let newd = Descriptor(ip: ip, hostname: hostname, handle: handle)
    
    switch handle {
    case .webSocket:
        log("New websocket connection from [\(newd.ip), \(newd.hostname)]")
        logToMud("Новое websocket соединение [\(newd.ip), \(newd.hostname)].",
            verbosity: .complete)
    default:
        log("New connection from [\(newd.ip), \(newd.hostname)]")
        logToMud("Новое соединение [\(newd.ip), \(newd.hostname)].",
            verbosity: .complete)
    }
    
    // Initialize descriptor data
    newd.state = .getCharset
    newd.handle = handle
    newd.loginTime = time(nil)
    
    Descriptor.lastDesc += 1
    newd.descNum = Descriptor.lastDesc
    
    networking.descriptors.insert(newd, at: 0)
    
    newd.send("") // Extra line for clarity
    if case .webSocket = handle {
        newd.send(textFiles.gameLogo)
        newd.state = .getAccountName
    } else {
        assert(newd.state == .getCharset)
        newd.send(selectCharset)
    }
    sendStatePrompt(newd)
}

// Send queued output out to the operating system
private func sendQueuedOutput(outputSet: inout fd_set) {
    for d in networking.descriptors {
        if !d.processOutput(outputSet: &outputSet) {
            d.closeSocket()
        }
    }
}

// Process descriptors with input pending
private func processPendingInput(inputSet: inout fd_set)
{
    for d in networking.descriptors {
        switch d.handle {
        case .socket(let socket):
            if inputSet.isSet(socket) {
                var totalBytesRead = 0
                var isError = false
                if !d.processInput(totalBytesRead: &totalBytesRead, isError: &isError) {
                    d.closeSocket()
                } else {
                    if totalBytesRead > 0 {
                        // New data was read, fetch commands
                        d.fetchCommandsFromInput()
                    }
                }
            }
        default:
            break
        }
    }
}
