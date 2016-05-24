//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

extension SecIdentity {
    
    /**
     * Helper to retrieve the identity's private key. Wraps `SecIdentityCopyPrivateKey()`.
     */
    public var privateKey: SecKey? {
        var privKey : SecKey?
        guard SecIdentityCopyPrivateKey(self, &privKey) == errSecSuccess else {
            return nil
        }
        return privKey
    }
    
}