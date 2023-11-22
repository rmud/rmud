import Foundation

private protocol TargetAction {
    var targetObjectIdentifier: ObjectIdentifier { get }
    func performAction()
}

class Scheduler {
    enum HandlerType {
        case movement
    }
    
    fileprivate struct Event {
        let gamePulse: UInt64
        let targetAction: TargetAction
    }
    
    private struct TargetActionWrapper<T: AnyObject>: TargetAction {
        let handlerType: HandlerType
        let target: T
        let action: (T) -> () -> ()

        var targetObjectIdentifier: ObjectIdentifier {
            return ObjectIdentifier(target)
        }
        
        func performAction() {
            action(target)()
        }
    }

    static let sharedInstance = Scheduler()
    
    let gameTime: GameTime
    
    private var eventsByTime = RedBlackTree<Event>()
    private var eventsByTarget: [ObjectIdentifier: Set<Event>] = [:]
    
    init(gameTime: GameTime = GameTime.sharedInstance) {
        self.gameTime = gameTime
    }
    
    func schedule<T: AnyObject>(afterGamePulses: UInt64, handlerType: HandlerType, target: T, action: @escaping (T) -> () -> ()) {
        let gamePulse = gameTime.gamePulse + afterGamePulses
        let targetAction = TargetActionWrapper(handlerType: handlerType, target: target, action: action)
        let event = Event(
            gamePulse: gamePulse,
            targetAction: targetAction)
        eventsByTime.insert(key: event)
        let targetId = ObjectIdentifier(target)
        var events = eventsByTarget[targetId] ?? []
        events.insert(event)
        eventsByTarget[targetId] = events
    }
    
    func cancelAllEvents<T: AnyObject>(target: T) {
        let targetId = ObjectIdentifier(target)
        guard var events = eventsByTarget[targetId] else { return }
        for event in events {
            eventsByTime.delete(key: event)
        }
        eventsByTarget.removeValue(forKey: targetId)
    }
    
    func runEvents() {
        let gamePulse = gameTime.gamePulse
        while let event = eventsByTime.minValue() {
            guard event.gamePulse <= gamePulse else { return }
            
            eventsByTime.delete(key: event)
            
            let targetId = event.targetAction.targetObjectIdentifier
            var events = eventsByTarget[targetId] ?? []
            events.remove(event)
            if !events.isEmpty {
                eventsByTarget[targetId] = events
            } else {
                eventsByTarget.removeValue(forKey: targetId)
            }
            
            event.targetAction.performAction()
        }
    }
}

extension Scheduler.Event: Equatable {
    static func == (lhs: Scheduler.Event, rhs: Scheduler.Event) -> Bool {
        return lhs.gamePulse == rhs.gamePulse
    }
}

extension Scheduler.Event: Comparable {
    static func < (lhs: Scheduler.Event, rhs: Scheduler.Event) -> Bool {
        return lhs.gamePulse < rhs.gamePulse
    }
}

extension Scheduler.Event: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(gamePulse)
    }
}
