extension Creature {
    func doHelp(context: CommandContext) {
        let separator = " "
        let groupSuffix = ":"
        send("Основные команды RMUD\n")
        let commandGroups = commandInterpreter.commandGroups
        let groupNameMaxLength = commandGroups.orderedKeys.max {
            $1.count > $0.count
        }?.count ?? 0
        for groupName in commandGroups.orderedKeys {
            let paddedGroupName = groupName.leftExpandingTo(groupNameMaxLength, with: " ")
            var line = "\(bCyn())\(paddedGroupName.uppercased())\(groupSuffix)\(nNrm())"
            var lineLength = groupName.count + groupSuffix.count // without ANSI codes
            for commandIndexEntry in commandGroups[groupName] ?? [] {
                guard !commandIndexEntry.command.flags.contains(.hidden) else {
                    continue
                }

                let commandName = commandIndexEntry.commandName
                let restOfCommand = commandName.suffix(commandName.count - commandIndexEntry.abbreviation.count)
                let newTextLength = (line.isEmpty ? 0 : separator.count) + commandName.count
                if lineLength + newTextLength > pageWidth {
                    send(line)
                    let indent = paddedGroupName.count + groupSuffix.count
                    line = String(repeating: " ", count: indent)
                    lineLength = indent
                }
                if !line.isEmpty {
                    line += separator
                }
                if nil != commandIndexEntry.command.handler {
                    line += "\(bGrn())\(commandIndexEntry.abbreviation)\(nNrm())\(restOfCommand)"
                } else {
                    line += "\(bRed())\(commandIndexEntry.abbreviation)\(nRed())\(restOfCommand)\(nNrm())"
                }
                lineLength += newTextLength
            }
            send(line)
        }
        send("\nПодробная информация доступна по команде СПРАВКА [команда]")
    }
}
