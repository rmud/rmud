extension Creature {
    func doQuitWarning(context: CommandContext) {
        send("Чтобы выбросить всё и выйти из игры, наберите команду \"конец!\" полностью.\n" +
             "Чтобы сохранить вещи, Вам нужно уйти на \"постой\" в ближайшей таверне.")
    }
}
