extension Creature {
    func doConsider(context: CommandContext) {
        guard let target = context.creature1 else {
            send("Кого Вы хотите сравнить по уровню со своим?")
            return
        }
        
        guard target != self else {
            send("Здесь, вероятно, следует засмеяться?")
            return
        }
        
        guard !target.isPlayer else {
            send("Вы не в состоянии определить примерный уровень персонажа.")
            return
        }
        
        let diff = Int(target.level) - Int(level)
        send(
            diff <= -10 ? "И не стыдно обижать маленьких?" :
            diff <= -5  ? "Вряд ли у Вас возникнут какие-либо проблемы." :
            diff <= -2  ? "Легко." :
            diff <= -1  ? "Сравнительно легко." :
            diff == 0   ? "Это будет честный бой!" :
            diff <= 1   ? "Вам понадобится чуть-чуть везения!" :
            diff <= 2   ? "Вам понадобится немало везения!" :
            diff <= 5   ? "Вы уверены, что Вам очень повезет?" :
            diff <= 10  ? "Вы с ума сошли?"
                        : "Должно быть, Вам нравится умирать?"
        )
    }
}
