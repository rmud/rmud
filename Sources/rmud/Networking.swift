import Foundation

class Networking {
    typealias Socket = Int32

    static let sharedInstance = Networking()

    static let invalidSocket: Int32 = -1
    
    // Максимальный размер в байтах буфера исходящего текста. При переполнении буфера
    // поступление текста будет приостановлено и пользователю будет выдано предупреждение
    // о переполнении.
    // Соединение при этом не разорвется.
    // Лимит мягкий, из-за особенностей реализации сетевого кода, допускается небольшое
    // превышение (в любом случае превышение не составит более чем двухкратный размер буфера).
    static let maxOutBufSize = 16 * 1024
    
    // Не обрезать строчки короче этой длины при превышении maxOutBufSize
    static let maxUntrimmableDataSize = 16 * 1024
    
    // Максимальный размер в байтах, который разрешено считать из сокета за одну операцию.
    static let maxSocketReadSize = 32768
    
    // Максимальный размер в байтах буфера входящего текста. При переполнении буфера
    // соединение будет разорвано.
    static let maxInBufSize = 4 * 1024 // Soft limit on player's input buffer length
    
    // При распарсивании буфера ввода, полные строки попадают в очередь команд: d->cmds
    // Эта константа задает максимальное кол-во команд, которое разрешено держать в очереди.
    // Если очередь заполнена - остальные команды останутся в буфере ввода в необработанном
    // виде.
    // Этот лимит введен в качестве защиты от спама: при переполнении буфера
    // ввода (который имеет размер MAX_RAW_INPUT_LENGTH), соединение будет разорвано.
    static let maxLinesInInputBuf = 20
    
    // Максимальная длина одной команды
    static let maxInputLength = 255
    
    var motherDescs = Set<Socket>() // материнские дескрипторы
    var descriptors = [Descriptor]()
    var topPlayersCountSinceBoot = 0

    func setupMotherSockets(ports: [UInt16]) {
        for port in ports {
            setupSocketOnPort(port)
        }
    }

    func closeMotherSockets() {
        for d in motherDescs {
            closeSocket(d)
        }
        motherDescs.removeAll()
    }
    
    func closeClosedDescriptors() {
        for d in descriptors {
            if d.state == .close {
                d.closeSocket()
            }
        }
    }
    
    private func setupSocketOnPort(_ port: UInt16) {
	#if os(Linux)
        let s: Socket = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
	#else
        let s: Socket = socket(AF_INET, SOCK_STREAM, 0)
	#endif
        if s < 0 {
            logSystemError("setup_mother_sockets: error while creating mother socket");
            exit(1)
        }
        
        var opt: Int32 = 1
        if setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout.stride(ofValue: opt))) < 0 {
            logSystemError("setup_mother_sockets: error while setting SO_REUSEADDR of mother socket");
            exit(1)
        }
        
        setSendBuf(s, Int32(Networking.maxOutBufSize))
        
        var ld = linger(l_onoff: 0, l_linger: 0)
        if setsockopt(s, SOL_SOCKET, SO_LINGER, &ld, socklen_t(MemoryLayout.stride(ofValue: ld))) < 0 {
            logSystemError("setup_mother_sockets: setsockopt SO_LINGER")
        }
        
        var saIn = sockaddr_in()
        let saInLength = socklen_t(MemoryLayout.stride(ofValue: saIn))
        saIn.sin_family = sa_family_t(AF_INET)
        saIn.sin_port = port.bigEndian
        saIn.sin_addr = getBindAddr()
        let bindResult = withUnsafePointer(to: &saIn) { saInPtr in
            saInPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                bind(s, saPtr, saInLength)
            }
        }
        if bindResult < 0 {
            logSystemError("bind");
            closeSocket(s)
            exit(1)
        }
        
        nonBlock(s)
        listen(s, 5)
        motherDescs.insert(s)
    }
    
    @discardableResult
    func setSendBuf(_ s: Socket, _ value: Int32) -> Bool {
        var opt: Int32 = value
        
        if setsockopt(s, SOL_SOCKET, SO_SNDBUF, &opt, socklen_t(MemoryLayout.stride(ofValue: opt))) < 0 {
            logSystemError("setsockopt SNDBUF");
            // This error is not critical
            return false
        }
        return true
    }
    
    private func getBindAddr() -> in_addr {
        var bindAddr = in_addr()
        bindAddr.s_addr = INADDR_ANY.bigEndian
        log("Binding to all ip addresses")
        return bindAddr
    }
    
    func nonBlock(_ s: Socket) {
        var flags = fcntl(s, F_GETFL, 0)
        flags |= O_NONBLOCK
        if fcntl(s, F_SETFL, flags) < 0 {
            logSystemError("Fatal error executing nonblock")
            exit(1)
        }
    }
    
    func closeSocket(_ s: Socket) {
        close(s)
    }    
}

