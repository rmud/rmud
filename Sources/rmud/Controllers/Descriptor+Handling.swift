import Foundation

extension Descriptor {
    func disconnectOtherDescriptorsWithMyAccount() {
        for d in networking.descriptors {
            if d !== self && d.account === account {
                d.closeSocket()
            }
        }
    }
}
