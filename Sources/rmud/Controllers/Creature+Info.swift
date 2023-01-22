import Foundation

extension Creature {
    // Will be multilingual in future depending on Creature's chosen language
    func onOff(_ value: Bool) -> String {
        return value ? "ВКЛ" : "ВЫКЛ"
    }
    
    private func pointColor(currentValue: Int, maximumValue: Int) -> String {
        let percent = maximumValue > 0 ? (100 * currentValue) / maximumValue : 0
        
        return percentageColor(percent)
    }

    func percentageColor(_ percent: Int) -> String {
        return percent >= 75 ? nGrn() :
            percent >= 25 ? bYel() :
            nRed()
    }
    
    func statusHitPointsColor() -> String {
        return pointColor(currentValue: hitPoints, maximumValue: affectedMaximumHitPoints())
    }
    
    func statusMovementColor() -> String {
        return pointColor(currentValue: movement, maximumValue: affectedMaximumMovement())
    }
}
