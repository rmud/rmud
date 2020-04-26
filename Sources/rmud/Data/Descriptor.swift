import Foundation
import Czlib
import WebSocket

class Descriptor {
    enum Handle {
        case socket(Networking.Socket)
        case webSocket(WebSocket)
    }
    
    static var lastDesc = 0 // Last assigned descriptor number
    static var zlibTmpOutBuf = [CChar](repeating: 0, count: Networking.maxOutBufSize * 2)
    static var readBuf = [CChar](repeating: 0, count: Networking.maxSocketReadSize)

    var descNum = 0 // Unique num assigned to desc

    //var descriptor: Networking.Socket = Networking.invalidSocket
    var handle: Handle
    var account: Account?
    var creature: Creature?

    var ip = ""
    var hostname = ""
    var badPasswordEntryAttempts = 0
    var state: DescriptorState = .getCharset
    var idleTicsAtPrompt = 0 // Tics idle at prompt
    var loginTime: time_t = 0 // When the person connected
    var isAtPrompt = false // Is the user at a prompt?
    var isEchoOn = true // Can be disabled on sensitive information entry
    var commandsInSourceEncoding = [[CChar]]()
    var commandsFromWebSocket = [String]()
    //var previousPrompt = ""
    
    //var fromMud: [CChar]
    //var toMud: [CChar]
    //var isCharsetUtf8 = false
    var charset: Charset = .utf8
    // FIXME: turn into flags (bitvector)?
    var workaroundZmudCp1251ZBug = false
    var iacOutBroken = false // Output & input charset preferences
    var iacInBroken = false
    let telnetMgr = TelnetMgr()
    // true if output buffer is currently in compressed zlib stream mode
    var zlibStrmOpen = false
    var zlibStrm = z_stream()
    var inBuf = [CChar]() // raw input buffer

    // Буфер данных для отсылки игроку. Поскольку может содержать
    // сжатые данные, прямые манипуляция с данными в буфере запрещены.
    // Используйте метод send_raw_data для добавления нового блока
    // данных в конец буфера.
    var outBuf = [CChar]() // raw output buffer
    var webSocketsOutputBuffer = WebSocketsBuffer()
    
    init(ip: String, hostname: String, handle: Handle) {
        self.ip = ip
        self.hostname = hostname
        self.handle = handle
        
        //fromMud = [CChar](repeating: 0, count: 256)
        //toMud = [CChar](repeating: 0, count: 256)
        //for i in 0 ..< 256 {
        //    fromMud[i] = CChar(bitPattern: UInt8(i))
        //    toMud[i] = CChar(bitPattern: UInt8(i))
        //}
    }
    
    deinit {
        if zlibStrmOpen {
            let derr = deflateEnd(&zlibStrm)
            if derr != Z_OK {
                logError("deflateEnd returned \(derr) in destructor. (in: \(zlibStrm.avail_in), out: \(zlibStrm.avail_out))")
            }
            zlibStrmOpen = false
        }
    }
    
    // Add a new string to a player's output queue
    private func writeToOutput(_ text: String, terminator: String = "\n", allowOverflow: Bool = false) {
        guard !text.isEmpty || !terminator.isEmpty else { return }
        
        if case .webSocket = handle {
            // FIXME: handle write overflow
            // FIXME: handle read overflow
            if isAtPrompt {
                webSocketsOutputBuffer.append(ansiText: "\n")
                isAtPrompt = false
            }
            if !text.isEmpty {
                webSocketsOutputBuffer.append(ansiText: text)
            }
            if !terminator.isEmpty {
                webSocketsOutputBuffer.append(ansiText: terminator)
            }
            return
        }
        
        if !allowOverflow && isOutBufOverflown() {
            return
        }
        
        var textUtf8 = [CChar]()
        if isAtPrompt {
            textUtf8 += [13, 10]
        }
        if var cString = text.cString(using: .utf8) {
            assert(cString.last! == 0)
            cString.removeLast()
            textUtf8 += replacingLfWithCrLf(in: cString)
        }
        if !terminator.isEmpty,
            var cString = terminator.cString(using: .utf8) {
                assert(cString.last! == 0)
                cString.removeLast()
                textUtf8 += replacingLfWithCrLf(in: cString)
        }
        
        var converted = convertEncodingFromMud(textUtf8)
        
        if !iacOutBroken {
            var result = [CChar]()
            result.reserveCapacity(converted.count * 2)
            for v in converted {
                switch v {
                case telnet.iac:
                    result.append(telnet.iac)
                    result.append(telnet.iac)
                default:
                    result.append(v)
                }
            }
            converted = result
        }
        
        var reportOverflow = false
        
        if allowOverflow {
            sendRawData(converted)
        } else if isOutBufOverflown(withAdditionalDataSize: converted.count) {
            var spaceLeftInBuffer = Networking.maxOutBufSize - outBuf.count
            if spaceLeftInBuffer < 0 {
                spaceLeftInBuffer = 0
            }
            if converted.count <= Networking.maxUntrimmableDataSize {
                // Allow soft overflow
                sendRawData(converted)
            } else {
                let trimmed = converted.prefix(upTo: Networking.maxUntrimmableDataSize)
                sendRawData(Array(trimmed))
            }
            reportOverflow = true
        } else {
            // Write complete string to output, then check for overflow
            sendRawData(converted)
            if isOutBufOverflown() {
                reportOverflow = true
            }
        }
        
        if reportOverflow {
            reportOverflowUnconditionally()
        }
        
        isAtPrompt = false // something was sent to player, he is no longer at prompt
    }
    
    private func isOutBufOverflown(withAdditionalDataSize size: Int = 0) -> Bool {
        return outBuf.count + size > Networking.maxOutBufSize
    }
    
    private func reportOverflowUnconditionally() {
        if state == .getCharset {
            writeToOutput("*** OVERFLOW ***", allowOverflow: true)
        } else {
            writeToOutput("*** ПЕРЕПОЛНЕНИЕ ***", allowOverflow: true)
        }
    }
    
    private func replacingLfWithCrLf(in text: [CChar]) -> [CChar] {
        var result = [CChar]()
        for c in text {
            switch c {
            case 10:
                result.append(13)
                result.append(10)
            default:
                result.append(c)
            }
        }
        return result
    }
        
    func convertEncodingFromMud(_ data: [CChar]) -> [CChar] {
        if charset == .utf8 {
            return data
        }
        //return charsets.applyTable(to: data, table: fromMud)
        guard let converted = Encoding.convert(fromCharset: .utf8, toCharset: charset, data: data) else {
            logError("Unable to convert data from utf8 to \(charset)")
            return data
        }
        return converted
    }

    func convertEncodingToMud(_ data: [CChar]) -> [CChar] {
        if charset == .utf8 {
            return data
        }
        //return charsets.applyTable(to: data, table: toMud)
        guard let converted = Encoding.convert(fromCharset: charset, toCharset: .utf8, data: data) else {
            logError("Unable to convert data from \(charset) to utf8")
            return data
        }
        return converted
    }
    
    private func sendRawData(_ data: [CChar]) {
        var data = data
        
        // This buffer size should be more than enough (compressed data
        // is usually smaller ;).
        // We multiply by 2 to take into the account that MAX_OUT_BUF_SIZE
        // limitation is soft, so actual buffer size can be up to 2 times
        // larger in rare cases.
        // Anyways, even if this buffer's size is lesser than neccessary,
        // the compression will be performed in a few steps and no error
        // will occur.
        if !telnetMgr.compressOutput {
            if zlibStrmOpen {
                // Close compression stream:
                zlibStrm.next_in = nil
                zlibStrm.avail_in = 0
                var ret: Int32 = 0
                repeat {
                    zlibStrm.avail_out = uInt(Descriptor.zlibTmpOutBuf.count)
                    Descriptor.zlibTmpOutBuf.withUnsafeMutableBufferPointer { bufferPtr in
                        bufferPtr.baseAddress!.withMemoryRebound(to: Bytef.self, capacity: bufferPtr.count) { bytefBufferPtr in
                            zlibStrm.next_out = bytefBufferPtr
                            ret = deflate(&zlibStrm, Z_FINISH) // no bad return value
                            assert(ret != Z_STREAM_ERROR) // state not clobbered
                        }
                    }
                    let have = Descriptor.zlibTmpOutBuf.count - Int(zlibStrm.avail_out)
                    if have > 0 {
                        outBuf += Descriptor.zlibTmpOutBuf.prefix(upTo: have)
                    }
                } while zlibStrm.avail_out == 0 // more data available, repeat
                assert(ret == Z_STREAM_END) // stream will be complete
                let derr = deflateEnd(&zlibStrm)
                if derr != Z_OK {
                    log("deflateEnd returned \(derr) when switching compression off " +
                        "in send_raw_data. (in: \(zlibStrm.avail_in), out: \(zlibStrm.avail_out))")
                }
                zlibStrm = z_stream()
                zlibStrmOpen = false
            }
            
            // Append the new data as plaintext:
            outBuf += data
            return
        }
        
        // Compression is enabled, initialize the compression stream if neccessary:
        if !zlibStrmOpen {
            zlibStrmOpen = true
            // Open compression stream:
            zlibStrm.zalloc = zlibAlloc
            zlibStrm.zfree = zlibFree
            zlibStrm.opaque = nil
            zlibStrm.next_in = nil
            zlibStrm.next_out = nil
            zlibStrm.avail_out = 0
            zlibStrm.avail_in = 0
            let derr = deflateInit_(&zlibStrm, Z_DEFAULT_COMPRESSION, ZLIB_VERSION, Int32(MemoryLayout.stride(ofValue: zlibStrm)))
            if derr != Z_OK {
                logError("descriptor_data::send_raw_data:: when calling zlib_strmInit");
                
                zlibStrm = z_stream()
                zlibStrmOpen = false
                
                // Do not try to recreate the stream when more data arrives:
                telnetMgr.compressOutput = false
                
                // Append the data as plaintext:
                outBuf += data
                return
            }
            
            // Stream was created successfully, send the magic sequence before starting
            // actually compressing the data:
            outBuf.append(telnet.iac)
            outBuf.append(telnet.sb)
            outBuf.append(telnet.teloptCompress2)
            outBuf.append(telnet.iac)
            outBuf.append(telnet.se)
        }
     
        // Append the compressed data:
        zlibStrm.avail_in = uInt(data.count)
        data.withUnsafeMutableBufferPointer { bufferPtr in
            bufferPtr.baseAddress!.withMemoryRebound(to: Bytef.self, capacity: bufferPtr.count) { byteBufferPtr in
                zlibStrm.next_in = byteBufferPtr
                
                // Run deflate() on input until output buffer not full, finish
                // compression if all of source has been read in
                repeat {
                    zlibStrm.avail_out = uInt(Descriptor.zlibTmpOutBuf.count)
                    Descriptor.zlibTmpOutBuf.withUnsafeMutableBufferPointer { bufferPtr in
                        bufferPtr.baseAddress!.withMemoryRebound(to: Bytef.self, capacity: bufferPtr.count) { bytefBufferPtr in
                            zlibStrm.next_out = bytefBufferPtr
                            let ret = deflate(&zlibStrm, Z_NO_FLUSH); // no bad return value
                            assert(ret != Z_STREAM_ERROR) // state not clobbered
                        }
                    }
                    let have = Descriptor.zlibTmpOutBuf.count - Int(zlibStrm.avail_out)
                    if have > 0 {
                        outBuf += Descriptor.zlibTmpOutBuf.prefix(upTo: have)
                    }
                } while (zlibStrm.avail_out == 0)
            }
        }
        assert(zlibStrm.avail_in == 0) // all input will be used
    }
    
    func sendBinaryData(_ data: [CChar]) {
        guard case .socket = handle else { return }
        
        let wasOverflown = isOutBufOverflown()
        sendRawData(data)
        if !wasOverflown && isOutBufOverflown() {
            reportOverflowUnconditionally()
        }
    }
    
    // Like send(), but won't start from newline if user is at prompt. Use for appending command typed by user to prompt.
    func sendAmendingPrompt(_ text: String) {
        let previousIsAtPrompt = isAtPrompt
        defer { isAtPrompt = previousIsAtPrompt }
        
        isAtPrompt = false
        send("\(Ansi.bYel)\(text)\(Ansi.nNrm)")
    }
    
    func sendAmendingPromptToAllDescriptors(_ text: String) {
        if let creature = creature, !creature.descriptors.isEmpty {
            creature.descriptors.forEach { descriptor in
                descriptor.sendAmendingPrompt(text)
                if descriptor !== self {
                    descriptor.isAtPrompt = false
                }
            }
        } else {
            sendAmendingPrompt(text)
        }
    }
    
    func send(_ text: String, terminator: String = "\n") {
        writeToOutput(text, terminator: terminator)
    }
    
    func sendPrompt(_ text: String) {
        let isCompact = creature?.preferenceFlags?.contains(.compact) ?? false
        if !isCompact {
            // Newline before prompt
            writeToOutput("")
        }
        writeToOutput(text, terminator: "")
        telnetGa()
        isAtPrompt = true
    }

    func compressionFlush() {
        if zlibStrmOpen {
            // Flush compression stream:
            zlibStrm.next_in = nil
            zlibStrm.avail_in = 0
            repeat {
                zlibStrm.avail_out = uInt(Descriptor.zlibTmpOutBuf.count)
                Descriptor.zlibTmpOutBuf.withUnsafeMutableBufferPointer { bufferPtr in
                    bufferPtr.baseAddress!.withMemoryRebound(to: Bytef.self, capacity: bufferPtr.count) { bytefBufferPtr in
                        zlibStrm.next_out = bytefBufferPtr
                        let ret = deflate(&zlibStrm, Z_SYNC_FLUSH) // no bad return value
                        assert(ret != Z_STREAM_ERROR) // state not clobbered
                    }
                }
                let have = Descriptor.zlibTmpOutBuf.count - Int(zlibStrm.avail_out)
                if have > 0 {
                    outBuf += Descriptor.zlibTmpOutBuf.prefix(upTo: have)
                }
            } while (zlibStrm.avail_out == 0) // more data available, repeat
        }
    }
    
    func closeSocket() {
        if let index = networking.descriptors.firstIndex(where: { $0 === self }) {
            networking.descriptors.remove(at: index)
        }
        switch handle {
        case .socket(let socket):
            networking.closeSocket(socket)
        case .webSocket(let webSocket):
            webSocket.close()
        }
        
        let accountEmail = account?.email ?? "no email"

        if let creature = creature {
            
            switch state {
            case .playing, .close:
                creature.descriptors.remove(self)
                if creature.inRoom != nil, creature.isPlayer, creature.descriptors.isEmpty {
                    act("1*и потерял1(,а,о,и) связь.", .toRoom, .excludingCreature(creature))
                    // FIXME
                    //save_char_safe(d->character, RENT_CRASH);
                    log("\(creature.nameNominative) [\(accountEmail), \(ip), \(hostname)] has lost the connection")
                    logToMud("\(creature.nameNominative) [\(accountEmail), \(ip), \(hostname)] теряет связь.", verbosity: .normal)
                }
                let _ = creature.putToLinkDeadState()
            default:
                let name = !creature.nameNominative.isEmpty ? creature.nameNominative : "Соединение без персонажа"
                let nameEnglish = !creature.nameNominative.isEmpty ? creature.nameNominative : "Connection without creature"
                log("\(nameEnglish) [\(accountEmail), \(ip), \(hostname)] is disconnecting")
                logToMud("\(name) [\(accountEmail), \(ip), \(hostname)] отсоединяется.", verbosity: .complete)
                self.creature = nil
            }
        } else {
            log("Connection without creature [\(accountEmail), \(ip), \(hostname)] has disconnected")
            logToMud("Соединение без персонажа [\(accountEmail), \(ip), \(hostname)] разрывается.", verbosity: .complete)
        }
        
        // FIXME: how can it happen that original.descriptor is not nil?
        //if let original = original, let originalDescriptor = original.descriptor {
            //originalDescriptor.handle = .none
        //}
        
        compressionFlush() // to avoid warning when destroying zlib's stream
    }
        
    // Send all of the output that we've accumulated for a player out to
    // the player's descriptor.
    //
    // Return value:
    //      False if connection should be closed, true otherwise.
    func processOutput(outputSet: inout fd_set) -> Bool {
        if case .socket(let socket) = handle {
            guard outputSet.isSet(socket) else {
                // Not ready to send more yet
                return true
            }
        }
        
        // Flush internal zlib's buffers so we can send all the data to user now:
        compressionFlush()
        
        switch handle {
        case .socket(let socket):
            if outBuf.isEmpty {
                return true // do nothing
            }

            var totalBytesSent = 0
            var bytesLeft = outBuf.count
            
            while bytesLeft > 0 {
                var bytesWritten = 0
                outBuf.withUnsafeBufferPointer { dataStart in
                    bytesWritten = write(socket, dataStart.baseAddress?.advanced(by: totalBytesSent), bytesLeft)
                }
                if bytesWritten < 0 {
                    if errno == EWOULDBLOCK || errno == EAGAIN || errno == EINTR {
                        outBuf = Array(outBuf.dropFirst(totalBytesSent))
                        return true // can not send more bytes as for now
                    }
                    logSystemError("While writing to socket")
                    outBuf = Array(outBuf.dropFirst(totalBytesSent))
                    return false
                }
                
                totalBytesSent += bytesWritten
                bytesLeft -= bytesWritten
            }
        case .webSocket(let webSocket):
            let encoder = JSONEncoder()
            encoder.outputFormatting = settings.websocketJsonWritingOptions
            for element in webSocketsOutputBuffer.elements {
                let jsonData: Data
                do {
                    jsonData = try element.encode(with: encoder)
                } catch {
                    log("Unable to encode websockets element: \(element); error: \(error.userFriendlyDescription)")
                    continue
                }
                webSocket.eventLoop.execute {
                    // FIXME: this flushes webSocket's channel on each send
                    webSocket.send(text: jsonData)
                }
            }
            webSocketsOutputBuffer.elements.removeAll(keepingCapacity: true)
        }
        
        // No bytes left in output buffer!
        outBuf.removeAll(keepingCapacity: true)
        
        return true
    }
    
    // Assumption: there will be no newlines in the raw input buffer when this
    // function is called. We must maintain that before returning.
    func processInput(totalBytesRead: inout Int, isError: inout Bool) -> Bool {
        
        guard case .socket(let socket) = handle else {
            assertionFailure()
            return false
        }
        
        totalBytesRead = 0
        isError = false
        
        while true {
            let readBufSize = Descriptor.readBuf.count
            var bytesRead = 0
            Descriptor.readBuf.withUnsafeMutableBufferPointer { readBufPtr in
                bytesRead = read(socket, readBufPtr.baseAddress, readBufSize)
            }
            if bytesRead < 0 {
                if errno != EWOULDBLOCK && errno != EAGAIN && errno != EINTR {
                    // We don't know what happened, cut them off
                    logSystemError("process_input: connection broken")
                    isError = true
                    return false // Some error condition was encountered on read
                } else {
                    return true // The read would have blocked, no data there
                }
            } else if bytesRead == 0 {
                //log("Connection broken by remote side.");
                return false // no error, but close connection
            }
            totalBytesRead += bytesRead
            
            telnetMgr.iacInBroken = iacInBroken
            
            guard let processedBuf = telnetMgr.process(data: Descriptor.readBuf, dataSize: bytesRead) else {
                logError("process_input: telnet_mgr abuse error")
                return false // close connection
            }
            
            // Charset conversion is performed in fetch_commands_from_input
            // for complete lines only!
            // It is not done here, because translit conversion (multichar to
            // single char) could break if one letter ("th" etc) arrives
            // splitted to two IP packets.
            if inBuf.count + processedBuf.count > Networking.maxInBufSize {
                logError("process_input: input buffer overflow")
                return false // close connection
            }
            inBuf += processedBuf
        }
    }
    
    func fetchCommandsFromInput() {
        guard commandsInSourceEncoding.count < Networking.maxLinesInInputBuf else { return }
        
        var at = 0
        var line = [CChar]()
        // isDelimOptional is false to keep uncompleted lines in input buffer
        while getDataDelim(data: inBuf, at: &at, out: &line, delim: [13, 10], isDelimOptional: false) {
            if line.count >= Networking.maxInputLength {
                if state != .getCharset {
                    writeToOutput("Введена слишком длинная строка, ввод укорочен.")
                } else {
                    writeToOutput("The entered line is too long, input is truncated.")
                }
                line = Array(line.prefix(upTo: Networking.maxInputLength))
            }
            
            //var converted = convertEncodingToMud(line) //charset_apply_table(line, d->to_mud);
          
            //converted.append(0)
            //let command = String(cString: converted)
            
            commandsInSourceEncoding.append(line)
            
            if commandsInSourceEncoding.count >= Networking.maxLinesInInputBuf {
                break
            }
        }
        if at > 0 {
            inBuf = Array(inBuf.dropFirst(at))
        }
    }
    
    func suggestCompression() {
        sendBinaryData([telnet.iac, telnet.will, telnet.teloptCompress2])
    }
    
    // Switch to binary mode
    func switchToBinary() {
        sendBinaryData([telnet.iac, telnet.doCommand, telnet.teloptBinary])
    }
    
    // Turn echo on
    func echoOn() {
        switch handle {
        case .socket:
            sendBinaryData([telnet.iac, telnet.wont, telnet.teloptEcho])
        case .webSocket:
            webSocketsOutputBuffer.append(command: .echoOn)
        }
        isEchoOn = true
    }
    
    // Turn echo off
    func echoOff() {
        switch handle {
        case .socket:
            sendBinaryData([telnet.iac, telnet.will, telnet.teloptEcho])
        case .webSocket:
            webSocketsOutputBuffer.append(command: .echoOff)
        }
        isEchoOn = false
    }
    
    func telnetGa() {
        sendBinaryData([telnet.iac, telnet.ga])
    }
    
    // Gets a substring delimited from the rest of a text with one of the delimiters supplied.
    // The delimiter is not captured, but is skipped after the substring is retrieved.
    //
    // Parameters:
    // [in]     text      Text to be scanned.
    // [in/out] at        Current position.
    // [out]    out       Target string.
    // [in]     delims    List of possible delimiters.
    // [in]     is_delim_optional
    //                    If true, the delimiter presence is optional, and the function will capture all
    //                    the text if there are no delimiters in it.
    //                    If false and there are no delimiters in the text, then the function will fail
    //                    and return false.
    //
    // Return value:
    //                    True, if a delimited substring was successfully captured and placed
    //                    into out parameter.
    //
    // Implementation details:
    //                    Function scans text for presence of ANY delimiter from delims in it,
    //                    not for a combination of delimiters. So, if text contains "string1\r string2",
    //                    but delims are "\r\n", then "\r" in text is condidered as a valid delimiter.
    //                    After fetching a substring from the text, the delimiters following it are skipped.
    //                    The delimiters are skipped in the order they appear in delims string,
    //                    but only once, consider these examples:
    //                    1) before: text[at]="string1\r\n\r\n string2" delims="\r\n",
    //                       after: text[at] = "\r\n string2"
    //                    2) before: text[at]="string1\r\r\n string2" delims="\r\n"
    //                       after: text[at] = "\r\n string2"
    //                    3) before: text[at]="string1\n\r\n string2" delims="\r\n"
    //                       after: text[at] = "\r\n string2"
    func getDataDelim(data: [CChar], at: inout Int, out: inout [CChar], delim: [CChar], isDelimOptional: Bool) -> Bool
    {
        let dataSize = data.count

        let prev = at
        while at < dataSize {
            if delim.contains(data[at]) {
                break
            }
            at += 1
        }
        // at now points to first delimiter (if any)
        
        if at == dataSize { // delimiter not found
            if isDelimOptional {
                out = Array(data.suffix(from: prev))
                return !out.isEmpty
            }
            at = prev // nothing was parsed, at must not move
            out.removeAll(keepingCapacity: true)
            return false
        }
        out = Array(data[prev ..< at]) // copy the string, excluding delimiters
        // Skip the delimiters:
        // The string isn't empty at this step, so we can assume
        // that in.size() > 0
        for d in delim {
            if at >= dataSize {
                break
            }
            if data[at] == d {
                at += 1
            }
        }
        return true
    }
}

extension Descriptor: Hashable {
    static func == (lhs: Descriptor, rhs: Descriptor) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

fileprivate func zlibAlloc(data: voidpf?, items: uInt, size: uInt) -> voidpf? {
    return malloc(Int(items * size))
}

fileprivate func zlibFree(opaque: voidpf?, address: voidpf?) {
    return free(address)
}

