import Foundation

class RaceInfo {
    var abbreviation = ""
    var namesByGender: [Gender: String] = [:]
    
    var heightMale: UInt = 0
    var heightFemale: UInt = 0
    var heightDiceNum = 0
    var heightDiceSize = 0
    
    var weightMale: UInt = 0
    var weightFemale: UInt = 0
    var weightDiceNum = 0
    var weightDiceSize = 0
    
    var strength = 0
    var dexterity = 0
    var constitution = 0
    var intelligence = 0
    var wisdom = 0
    var charisma = 0

    var size: UInt8 = 0
    var movement = 0
}
