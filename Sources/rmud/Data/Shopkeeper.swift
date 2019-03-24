import Foundation

struct Shopkeeper {
    // Factors to multiply cost with
    var sellProfit: Int?
    var buyProfit: Int?
    var repairProfit: Int?
    var repairLevel: UInt8?
    
    var producingItemVnums: Set<Int> = []
    
    var buyingItemsOfType: Set<ItemType> = []
    var restrictFlags: ItemAccessFlags = [] // Who does the shop trade with
    
    func isProducing(vnum: Int) -> Bool {
        return producingItemVnums.contains(vnum)
    }
    
    func isProducing(item: Item) -> Bool {
        return isProducing(vnum: item.vnum)
    }
    //bool my_production(vnum itemvn);
    //bool my_production(obj_data* obj) { return my_production(obj->vn); }
    
    init() {
    }
}
