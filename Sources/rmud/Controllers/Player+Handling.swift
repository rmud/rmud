import Foundation

extension Player {
    func renderMap(highlightingRooms: Set<Int> = [], markingRooms: Set<Int> = []) -> RenderedAreaMap? {
        guard let areaMap = creature.inRoom?.area?.map else { return nil }
        let isHolylight = preferenceFlags.contains(.holylight)
        let configuration = RenderedAreaMap.RenderConfiguration(
            exploredRooms: .some(exploredRooms),
            showUnexploredRooms: isHolylight,
            highlightedRooms: highlightingRooms,
            markedRooms: markingRooms)
        return RenderedAreaMap(areaMap: areaMap, renderConfiguration: configuration)
    }
    
    func stopWatching() -> Bool {
        //XXX ещё подобное действие выпоняется в make_pronpt() (act.informative.cpp)
        //т.к. в тот момент act() не сработает
        guard let watching = watching else {
            return false
        }
        act("Вы прекратили наблюдать за состоянием 2р.",
            .toSleeping, .toCreature(creature), .excludingCreature(watching))
        self.watching = nil
        return true
    }
}
