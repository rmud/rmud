import Foundation

struct Event<EventId> {
    var eventId: EventId
    var actionFlags: EventActionFlags = []
    var isAllowed: Bool {
        return !actionFlags.contains(.denyAction)
    }
    var toActor: String? // перехват.игроку
    var toVictim: String? // перехват.жертве
    var toRoomExcludingActor: String? // перехват.комнате
    //var toRoomExcludingActorAndVictim: String? // перехват.остальным
    
    init(eventId: EventId) {
        self.eventId = eventId
    }
}


