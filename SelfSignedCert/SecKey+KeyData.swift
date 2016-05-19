//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

extension SecKey {
    var keyData: [UInt8] {
        let query = [ kSecValueRef as String : self, kSecReturnData as String : true ]
        var out: AnyObject?
        guard errSecSuccess == SecItemCopyMatching(query, &out) else {
            return []
        }
        guard let data = out as? NSData else {
            return []
        }
        return data.bytes
    }
}
