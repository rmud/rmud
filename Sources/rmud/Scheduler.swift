import Foundation

private protocol TargetAction {
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
    
    fileprivate struct TargetActionWrapper<T: AnyObject>: TargetAction {
        let handlerType: HandlerType
        let target: T
        let action: (T) -> () -> ()
        
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
    
    func schedule<T: AnyObject>(afterGamePulses: UInt64, handlerType:  HandlerType, target: T, action: @escaping (T) -> () -> ()) {
        let gamePulse = gameTime.gamePulse + afterGamePulses
        log("schedule at: \(gamePulse)")
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
    
    func runEvents() {
        let gamePulse = gameTime.gamePulse
        while let event = eventsByTime.minValue() {
            log("check: \(event.gamePulse) <= \(gamePulse)")
            guard event.gamePulse <= gamePulse else { return }
            eventsByTime.delete(key: event)
            log("triggered: \(event.gamePulse)")
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
