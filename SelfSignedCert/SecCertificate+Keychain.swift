//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

extension SecCertificate {
    func storeInKeychain() -> OSStatus {
        let dict : [String:AnyObject] = [kSecClass as String: kSecClassCertificate as String,
                                         kSecValueRef as String : self]
        return SecItemAdd(dict, nil)
    }
    
}