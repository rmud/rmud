// https://stackoverflow.com/questions/41416316/how-to-cast-between-cfstring-and-string-with-swift-on-linux?rq=1
import Foundation
#if os(Linux)
import CoreFoundation
import Glibc
#endif
public extension String {
    func transformedToLatinStrippingDiacritics() -> String {
        let chars = Array(self.utf16)
        let cfStr = CFStringCreateWithCharacters(nil, chars, self.utf16.count)
        let str = CFStringCreateMutableCopy(nil, 0, cfStr)!
        if CFStringTransform(str, nil, kCFStringTransformToLatin, false) {
            if CFStringTransform(str, nil, kCFStringTransformStripDiacritics, false) {
                return String(describing: str)
            }
            return self
        }
        return self
    }
}
