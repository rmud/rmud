import Foundation

// Object frag types and saving throws
enum SpellClass: UInt8 {
    case neutral     = 0  // does nothing important
    case harm        = 1  // cone of cold, magic missile
    case harmSpecial = 2  // dispel evil, good
    case massHarm    = 3  // prismatic spray, fireball
    case curse       = 4  // blindness, curse, silence
    case cure        = 5  // remove curse, remove poison
    case massCurse   = 6  // sunray, mass curse
    case detect      = 7  // see invis, detect magic
    case offensive   = 8  // charm, hold person
    case defensive   = 9  // shield, fireshield
    case heal        = 10 // cure_*, heal
}
