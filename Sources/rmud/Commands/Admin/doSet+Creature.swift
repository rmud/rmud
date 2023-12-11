import Foundation

extension Creature {
    func setCreature(named name: String, field: String, value: String) {
        guard !name.isEmpty else {
            send("Укажите имя персонажа или монстра.")
            return
        }
        
        var creatures: [Creature] = []
        var items: [Item] = []
        var room: Room?
        var string = ""
        
        let scanner = Scanner(string: name)
        guard fetchArgument(
            from: scanner,
            what: .creature,
            where: .world,
            cases: .accusative,
            condition: nil,
            intoCreatures: &creatures,
            intoItems: &items,
            intoRoom: &room,
            intoString: &string
        ) else {
            send("Персонажа с таким именем не существует.")
            return
        }

        if let creature = creatures.first {
            setField(of: creature, field: field, value: value)
        }
    }
    
    func showCreatureFields() {
        send("уровень")
    }
    
    private func setField(of creature: Creature, field: String, value: String) {
        if field.isAbbrevCI(ofAny: ["уровень", "level"]) {
            let level = Int(value)
            guard let level, level >= 1, level <= 30 else {
                send("Укажите значение в диапазоне [1 ... \(maximumMortalLevel)].")
                return
            }
            creature.setLevel(level)
        }
    }
    
    private func setLevel(_ newLevel: Int) {
        if isMobile {
            level = UInt8(newLevel)
        } else {
            if newLevel > level {
                let experienceNeeded = Int(classId.info.experienceForLevel(newLevel)) - experience
                gainExperience(experienceNeeded, withSafetyLimits: false)
            } else if newLevel < level {
                let loss = experience - Int(classId.info.experienceForLevel(newLevel))
                gainExperience(-loss, withSafetyLimits: false)
            }
        }
    }
}
