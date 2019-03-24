import Foundation
import Dispatch

struct AtomicBoolean {
    private var semaphore = DispatchSemaphore(value: 1)
    private var data: Bool = false
    var value: Bool  {
        get {
            semaphore.wait()
            let tmp = data
            semaphore.signal()
            return tmp
        }
        set {
            semaphore.wait()
            data = newValue
            semaphore.signal()
        }
    }
    
}

