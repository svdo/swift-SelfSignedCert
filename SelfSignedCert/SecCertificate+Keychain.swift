//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

extension SecCertificate {
    func storeInKeychain() -> OSStatus {
        let dict : [NSString:AnyObject] = [kSecClass as NSString: kSecClassCertificate as NSString,
                                         kSecValueRef as NSString : self]
        return SecItemAdd(dict as CFDictionary, nil)
    }
    
}
