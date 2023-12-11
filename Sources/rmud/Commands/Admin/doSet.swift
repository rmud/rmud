import Foundation

extension Creature {
    func doSet(context: CommandContext) {
        let usage = "установить <области|комнате|монстру|предмету> <номер> [поле значение]"
        
        guard !context.argument1.isEmpty else {
            send(usage)
            return
        }
        if context.isSubCommand1(oneOf: ["области", "область", "area"]) {
            setAreaField(context: context)
        } else if context.isSubCommand1(oneOf: ["комнате", "комната", "room"]) {
            setRoomField(context: context)
        } else if context.isSubCommand1(oneOf: ["монстру", "монстр", "mobile"]) {
            setMobileField(context: context)
        } else {
            send("Неизвестная подкоманда.")
            send(usage)
        }
    }
    
    private func setAreaField(context: CommandContext) {
        guard let field = context.scanWord() else {
            send("Вы можете установить следующие поля области:")
            showAreaPrototypeFields()
            return
        }
        let value = context.restOfString()
        guard !value.isEmpty else {
            send("Укажите значение.")
            return
        }
        setAreaPrototypeField(areaName: context.argument2, fieldName: field, value: value)
    }
    
    private func setRoomField(context: CommandContext) {
        guard let vnum = roomVnum(fromArgument: context.argument2) else {
            send("Некорректный номер комнаты.")
            return
        }
        guard let field = context.scanWord() else {
            send("Вы можете установить следующие поля комнаты:")
            showRoomPrototypeFields()
            return
        }
        let value = context.restOfString()
        guard !value.isEmpty else {
            send("Укажите значение.")
            return
        }
        setRoomPrototypeField(vnum: vnum, fieldName: field, value: value)
    }
    
    private func setMobileField(context: CommandContext) {
        guard !context.argument2.isEmpty else {
            send("Укажите номер монстра.")
            return
        }
        if let vnum = Int(context.argument2) {
            setMobilePrototype(vnum: vnum, context: context)
        } else {
            setMobile(named: context.argument2, context: context)
        }
    }
    
    private func setMobilePrototype(vnum: Int, context: CommandContext) {
        guard let field = context.scanWord() else {
            send("Вы можете установить следующие поля монстра:")
            showMobilePrototypeFields()
            return
        }
        let value = context.restOfString()
        guard !value.isEmpty else {
            send("Укажите значение.")
            return
        }
        setMobilePrototypeField(vnum: vnum, fieldName: field, value: value)
    }
    
    private func setMobile(named name: String, context: CommandContext) {
        guard let field = context.scanWord() else {
            send("Вы можете установить следующие поля монстра:")
            showCreatureFields()
            return
        }
        let value = context.restOfString()
        guard !value.isEmpty else {
            send("Укажите значение.")
            return
        }
        setCreature(named: name, field: field, value: value)
    }
    
    private func showAreaPrototypeFields() {
        let text = format(fieldDefinitions: db.definitions.areaFields)
        send(text)
    }
    
    private func showRoomPrototypeFields() {
        let text = format(fieldDefinitions: db.definitions.roomFields)
        send(text)
    }

    private func showMobilePrototypeFields() {
        let text = format(fieldDefinitions: db.definitions.mobileFields)
        send(text)
    }
    
    private func format(fieldDefinitions: FieldDefinitions) -> String {
        var result = ""
        
        for (index, fieldName) in fieldDefinitions.fieldsByLowercasedName.keys.sorted().enumerated() {
            if index != 0 {
                result += "\n"
            }
            result += fieldName.uppercased() //.rightExpandingTo(20)
        }
        return result
    }
}
