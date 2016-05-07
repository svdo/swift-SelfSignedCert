//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import Security

extension SecKey {

    static func generateKeyPair(ofSize bits:UInt) throws -> (privateKey:SecKey, publicKey:SecKey) {
        let pubKeyAttrs = [ kSecAttrIsPermanent as String: true ]
        let privKeyAttrs = [ kSecAttrIsPermanent as String: true ]
        let params: NSDictionary = [ kSecAttrKeyType as String : kSecAttrKeyTypeRSA as String,
                       kSecAttrKeySizeInBits as String : bits,
                       kSecPublicKeyAttrs as String : pubKeyAttrs,
                       kSecPrivateKeyAttrs as String : privKeyAttrs ]
        var pubKey: SecKey?
        var privKey: SecKey?
        let status = SecKeyGeneratePair(params, &pubKey, &privKey)
        if (status != errSecSuccess) {
            throw NSError(domain:"SelfSignedCert", code: 1, userInfo: ["OSStatus":NSNumber(int: status)])
        }
        guard let pub = pubKey else {
            throw NSError(domain:"SelfSignedCert", code: 2, userInfo: nil)
        }
        guard let priv = privKey else {
            throw NSError(domain:"SelfSignedCert", code: 3, userInfo: nil)
        }
        return (priv, pub)
    }
    
    var blockSize: Int {
        return SecKeyGetBlockSize(self)
    }
}
