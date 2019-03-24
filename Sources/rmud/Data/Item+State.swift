import Foundation

extension Item {
//    func canLoadMore() -> Bool {
//        guard let loadMaximum = maximumCountInWorld else { return true }
//        return (db.itemsCountByVnum[vnum] ?? 0) < loadMaximum
//    }
    
    // FIXME: overrides which cancel action should probably be prioritized
    func override(eventIds: [ItemEventId]) -> Event<ItemEventId> {
        let chosenId: ItemEventId
        if eventIds.isEmpty {
            assertionFailure()
            chosenId = .invalid
        } else {
            chosenId = .invalid // FIXME
        }
        //        for override in actionOverrides {
        //            if override.action == action {
        //                return override
        //            }
        //        }
        return Event<ItemEventId>(eventId: chosenId)
    }

    func override(eventIds: ItemEventId...) -> Event<ItemEventId> {
        return override(eventIds: eventIds)
    }

    func override(eventId: ItemEventId) -> Event<ItemEventId> {
        return override(eventIds: eventId)
    }
}
