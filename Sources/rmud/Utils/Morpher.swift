import Foundation

class Morpher {
    static let sharedInstance = Morpher()

    var isEnabled: Bool = false
    
    func tryEnabling() -> Bool {
        isEnabled = false
        
        do {
            let (result, code) = try shell(
                executable: "Tools/detect_gender.php", arguments: ["Карамон"])
            guard code == 0 && result == "1" else { return false }
        } catch {
            return false
        }

        do {
            let (result, code) = try shell(
                executable: "Tools/detect_gender.php", arguments: ["Тика"])
            guard code == 0 && result == "2" else { return false }
        } catch {
            return false
        }
        
        do {
            let (result, code) = try shell(
                executable: "Tools/generate_name_cases.php", arguments: ["Карамон", "1"])
            guard code == 0 && result == "Карамона Карамону Карамона Карамоном Карамоне" else { return false }
        } catch {
            return false
        }

        do {
            let (result, code) = try shell(
                executable: "Tools/generate_name_cases.php", arguments: ["Тика", "2"])
            guard code == 0 && result == "Тики Тике Тику Тикой Тике" else { return false }
        } catch {
            return false
        }

        isEnabled = true
        
        return true
    }
    
    func isWorking() -> Bool {
        
        return true
    }
    
    func detectGender(name: String) -> Gender {
        guard isEnabled else {
            return .masculine
            
        }

        let (result, code) = try! shell(
            executable: "Tools/detect_gender.php", arguments: [name])
        guard code == 0, let value = result else {
            assertionFailure()
            return .masculine
        }
        switch value {
        case "2":
            return .feminine
        default:
            return .masculine
        }
    }
    
    func generateNameCases(name: String, gender: Gender) -> (genitive: String, dative: String, accusative: String, instrumental: String, prepositional: String) {
        guard isEnabled else { return (name, name, name, name, name) }

        let genderString = (gender == .feminine ? "2" : "1")
        
        let (result, code) = try! shell(
            executable: "Tools/generate_name_cases.php", arguments: [name, genderString])
        guard code == 0, let value = result else {
            assertionFailure()
            return (name, name, name, name, name)
        }
        let cases = value.split(separator: " ")
        guard cases.count == 5 else {
            assertionFailure()
            return (name, name, name, name, name)
        }

        return (cases[0].precomposedStringWithCanonicalMapping,
                cases[1].precomposedStringWithCanonicalMapping,
                cases[2].precomposedStringWithCanonicalMapping,
                cases[3].precomposedStringWithCanonicalMapping,
                cases[4].precomposedStringWithCanonicalMapping)
    }
}
