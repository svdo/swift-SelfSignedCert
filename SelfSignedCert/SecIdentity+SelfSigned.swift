//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import Security

extension SecIdentity
{

    static func createSelfSigned(ofSize bits:UInt = 2048) throws -> SecIdentity? {
//        let (privKey,pubKey) = try SecKey.generateKeyPair(ofSize: bits)
//        let certRequest = CertificateRequest(forPublicKey:pubKey, name: "Stefan van den Oord", email: "soord@mac.com", keyUsage: [.DigitalSignature, .DataEncipherment])
//        let signedCert = certRequest.sign(withPrivateKey:privKey)
//        // Store signed SecCertificate in keychain
//        // Find identiy in keychain based on public key digest
//        // return identity
        return nil
    }

}