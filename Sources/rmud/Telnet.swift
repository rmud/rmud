import Foundation

class Telnet {
    static let sharedInstance = Telnet()
 
    let iac = CChar(bitPattern: UInt8(255))
    let will = CChar(bitPattern: UInt8(251))
    let wont = CChar(bitPattern: UInt8(252))
    let doCommand = CChar(bitPattern: UInt8(253))
    let dont = CChar(bitPattern: UInt8(254))
    let sb = CChar(bitPattern: UInt8(250))
    let ga = CChar(bitPattern: UInt8(249))
    let se = CChar(bitPattern: UInt8(240))

    let teloptCompress2 = CChar(bitPattern: UInt8(86))
    let teloptEcho = CChar(bitPattern: UInt8(1))
    let teloptBinary = CChar(bitPattern: UInt8(0))
}
