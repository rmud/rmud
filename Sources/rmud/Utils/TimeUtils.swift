import Foundation

// Zero-valued time structure
var nullTime = timeval(tv_sec: 0, tv_usec: 0)

// Returns the time difference between a and b. floors at 0
func timediff(_ a: timeval, _ b: timeval) -> timeval {
    if a.tv_sec < b.tv_sec {
        return nullTime
    } else if a.tv_sec == b.tv_sec {
        if a.tv_usec < b.tv_usec {
            return nullTime
        } else {
            return timeval(tv_sec: 0, tv_usec: a.tv_usec - b.tv_usec)
        }
    } else {
        var result = timeval()
        result.tv_sec = a.tv_sec - b.tv_sec
        if (a.tv_usec < b.tv_usec) {
            result.tv_usec = a.tv_usec + 1000000 - b.tv_usec
            result.tv_sec -= 1
        } else {
            result.tv_usec = a.tv_usec - b.tv_usec
        }
        return result
    }
}

// Adds 2 time values
func timeadd(_ a: timeval, _ b: timeval) -> timeval {
    var result = timeval(tv_sec: a.tv_sec + b.tv_sec, tv_usec: a.tv_usec + b.tv_usec)
    
    while result.tv_usec >= 1000000 {
        result.tv_usec -= 1000000
        result.tv_sec += 1
    }
    return result
}
