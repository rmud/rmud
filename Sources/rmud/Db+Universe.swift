//import Foundation
//import Essentials

//extension Db {
//    func loadUniverse() throws {
//        let data = try String(contentsOfFile: filenames.universe, encoding: .utf8)
//
//        var currentLine = 0
//
//        data.forEachLine { line, stop in
//            currentLine += 1
//
//            let trimmed = line.trimmingCharacters(in: .whitespaces)
//            if trimmed.isEmpty || trimmed.first! == ";" {
//                return
//            }
//
//            let scanner = Scanner(string: trimmed)
//
//            let field = scanner.scanUpToCharacters(from: .whitespaces) ?? ""
//            let areaName = scanner.scanUpToCharacters(from: .whitespaces) ?? ""
//
//            if field.isEmpty || areaName.isEmpty {
//                universeReportErrorAndExit(currentLine: currentLine)
//            }
//
//            switch field.lowercased() {
//            case "область":
//                let roomFrom = scanner.scanInteger() ?? 0
//                let roomTo = scanner.scanInteger() ?? 0
//                let resetInterval = scanner.scanInteger() ?? 0
//                let resetMode = AreaResetMode(rawValue: UInt8(exactly: scanner.scanInteger() ?? 0) ?? 0) ?? .never
//
//                if scanner.isAtEnd {
//                    universeReportErrorAndExit(currentLine: currentLine)
//                }
//
//                let description = scanner.scanUpTo("") ?? ""
//
//                let areaPrototype = AreaPrototype()
//                areaPrototype.areaName = areaName
//                areaPrototype.vnumRange = roomFrom ..< (roomTo + 1)
//                areaPrototype.resetInterval = resetInterval
//                areaPrototype.resetMode = resetMode
//                areaPrototype.description = description
//
//                db.worldPrototypes.areaPrototypesByLowercasedId[areaName.lowercased()] = areaPrototype
//
//                //log("Area \"\(areaName)\": \(roomFrom) ... \(roomTo)")
//            default:
//                universeReportErrorAndExit(currentLine: currentLine)
//            }
//        }
//    }
//
//    private func universeReportErrorAndExit(currentLine: Int) {
//        logFatal("Format error in universe file \"\(filenames.universe)\", строка \(currentLine)")
//    }
//}

