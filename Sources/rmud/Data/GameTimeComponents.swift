import Foundation

struct GameTimeComponents {
    var years: Int
    var months: Int
    var days: Int
    var hours: Int
    
    init(gameSeconds: UInt64) {
        hours = Int((gameSeconds / secondsPerGameHour) % hoursPerGameDay) // 0..23 hours
        days = Int((gameSeconds / secondsPerGameDay) % daysPerGameMonth) // 0..29 days
        months = Int((gameSeconds / secondsPerGameMonth) % monthsPerGameYear) // 0..11 months
        years = Int((gameSeconds / secondsPerGameYear)) // 0..99 years
    }
}
