import Foundation
import CoreFoundation

private let logDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return dateFormatter
}()

func log(_ text: String) {
    //var ct = time(nil)
    //let lt = localtime(&ct)

    //let timeString: String
    //if let timeCString = asctime(lt) {
    //    timeCString[Int(strlen(timeCString)) - 1] = 0
    //    timeString = String(cString: timeCString)
    //} else {
    //    timeString = "?"
    //}

    let transformedText = !settings.transliterateLogs ? text : text.transformedToLatinStrippingDiacritics()
    
    let timeString = logDateFormatter.string(from: Date())
    print("\(timeString): \(transformedText)")
    fflush(stdout)
}

func log(error: Error) {
    log("ERROR: \(error.userFriendlyDescription)".capitalizingFirstLetter())
    if settings.fatalWarnings { exit(1) }
}

func logWarning(_ text: String) {
    log("WARNING: \(text)")
    if settings.fatalWarnings { exit(1) }
}

func logError(_ text: String) {
    log("ERROR: \(text)")
    if settings.fatalWarnings { exit(1) }
}

func logFatal(_ text: String) -> Never {
    log("ERROR: \(text)")
    exit(1)
}

func logFatal(error: Error) {
    log(error: error)
    exit(1)
}

func logSystemError(_ text: String) {
    let description = String(cString: strerror(errno))
    log("ERROR: \(text): \(description)")
}

func logIntervention(_ text: String) {
    // FIXME: log to Filenames.immlog
    log("INTERVENTION: \(text)")
}

// Log mud messages to a file and to online imm's syslogs
// toplevel is used in case of sending a shorten form of a message
// to imms, who's level is not greater than toplevel
// this shorten messages are never written into logfile
func logToMud(_ text: String, verbosity: MudlogVerbosity, roles: Roles = [.admin]) {
    let output = "[ \(text) ]"
    
    for descriptor in networking.descriptors {
        guard descriptor.state == .playing else { continue }
        guard let creature = descriptor.creature else { continue }
        guard let player = creature.player else { continue }
        guard player.preferenceFlags.mudlogVerbosity >= verbosity else { continue }
        guard roles.isEmpty || !roles.intersection(player.roles).isEmpty else { continue }
        descriptor.send("\(creature.nGrn())\(output)\(creature.nNrm())")
    }
}

