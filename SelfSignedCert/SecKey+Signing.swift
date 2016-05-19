//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import IDZSwiftCommonCrypto

extension SecKey {
    
    func sign(data data:[UInt8]) -> [UInt8] {
        let sha1 = Digest(algorithm: .SHA1)
        sha1.update(data)
        let digest = sha1.final()
        
        var signature = [UInt8](count:1024, repeatedValue:0)
        var signatureLength = 1024
        let status = SecKeyRawSign(self, .PKCS1SHA1, digest, digest.count, &signature, &signatureLength)
        guard status == errSecSuccess else {
            return []
        }
        let realSignature = signature[0 ..< signatureLength]
        return Array(realSignature)
    }
    
}
