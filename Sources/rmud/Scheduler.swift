import Foundation

private protocol TargetAction {
    func performAction()
}

class Scheduler {
    fileprivate struct Event {
        let gamePulse: UInt64
        let targetAction: TargetAction
    }
    
    private struct TargetActionWrapper<T: AnyObject>: TargetAction {
        var target: T
        let action: (T) -> () -> ()
        
        func performAction() {
            action(target)()
        }
    }

    static let sharedInstance = Scheduler()
    
    let gameTime: GameTime
    
    private var events = RedBlackTree<Event>()
    
    init(gameTime: GameTime = GameTime.sharedInstance) {
        self.gameTime = gameTime
    }
    
    func schedule<T: AnyObject>(afterGamePulses: UInt64, target: T, action: @escaping (T) -> () -> ()) {
        let gamePulse = gameTime.gamePulse + afterGamePulses
        log("schedule at: \(gamePulse)")
        let event = Event(
            gamePulse: gamePulse,
            targetAction: TargetActionWrapper(target: target, action: action))
        events.insert(key: event)
    }
    
    func runEvents() {
        let gamePulse = gameTime.gamePulse
        while let event = events.minValue() {
            log("check: \(event.gamePulse) <= \(gamePulse)")
            guard event.gamePulse <= gamePulse else { return }
            events.delete(key: event)
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
