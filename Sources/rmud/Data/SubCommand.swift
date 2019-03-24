import Foundation

enum SubCommand {
    case none
    
    // doMove
    case north
    case east
    case south
    case west
    case up
    case down
    
    // doQuit
    case quit

    // doService
    case shopList
    case shopBuy
    case shopRepair
    case shopEvaluate
    case shopSell
    case shopEstimate
    case shopBrowse
}
