import Foundation
#if os(macOS)
import Darwin
#else
import Glibc
#endif

class BenchmarkTimer {
    private var begin: clock_t?
    private var end: clock_t?
    
    init() {
    }
    
    var elapsed: Double {
        guard let begin = begin, let end = end else { return 0.0 }
        return Double(end - begin) / Double(CLOCKS_PER_SEC)
    }
    
    func start() {
        begin = clock()
        end = nil
    }
    
    func stop() {
        assert(begin != nil)
        end = clock()
    }
    
    static func measure(_ what: String = "", block: () throws -> ()) throws {
        let timer = BenchmarkTimer()
        timer.start()

        do {
            try block()
        } catch {
            timer.stop()
            throw error
        }

        timer.stop()
        if !what.isEmpty {
            log("\(what): \(timer.elapsed) sec")
        } else {
            log("  ...took \(timer.elapsed) sec")
        }
    }

    static func measure(_ what: String = "", block: ()->()) {
        let timer = BenchmarkTimer()
        timer.start()
        defer {
            timer.stop()
            if !what.isEmpty {
                log("\(what): \(timer.elapsed) sec")
            } else {
                log("  ...took \(timer.elapsed) sec")
            }
        }
        block()
    }
}
