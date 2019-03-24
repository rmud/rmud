import Foundation

func affected<T: NumericType>(baseValue: T, by apply: Apply) -> T {
    // TODO. Be careful not to trigger exception on integer overflow
    
    return baseValue
}

func affected<T: NumericType>(baseValue: T, by apply: Apply, clampedTo range: ClosedRange<T>) -> T {
    return max(range.lowerBound,
               min(range.upperBound,
                   affected(baseValue: baseValue, by: apply)))
}

