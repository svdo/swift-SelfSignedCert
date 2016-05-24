//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import Security
import IDZSwiftCommonCrypto

extension SecIdentity
{

    static func create(ofSize bits:UInt = 3072) throws -> SecIdentity? {
        let (privKey,pubKey) = try SecKey.generateKeyPair(ofSize: bits)
        let certRequest = CertificateRequest(forPublicKey:pubKey, subjectCommonName: "Stefan van den Oord", subjectEmailAddress: "soord@mac.com", keyUsage: [.DigitalSignature, .DataEncipherment])
        let signedBytes = try certRequest.selfSign(withPrivateKey:privKey)
        guard let signedCert = SecCertificateCreateWithData(nil, NSData(bytes:signedBytes)) else {
            return nil
        }
        
        signedCert.storeInKeychain()

        return findIdentity(forPrivateKey:privKey, publicKey:pubKey)
    }
    
    private static func findIdentity(forPrivateKey privKey:SecKey, publicKey pubKey:SecKey) -> SecIdentity? {
        guard let identities = SecIdentity.findAll(withPublicKey:pubKey) else {
            return nil
        }
        
        for identity in identities {
            if let priv = identity.privateKey where priv.keyData == privKey.keyData {
                return identity
            }
        }
        return nil
    }
    
    static func findAll(withPublicKey pubKey:SecKey) -> [SecIdentity]? {
        let sha1 = Digest(algorithm: .SHA1)
        sha1.update(pubKey.keyData)
        let digest = sha1.final()
        let digestData = NSData(bytes: digest)
        
        var out: AnyObject?
        let query : [String:AnyObject] = [kSecClass as String: kSecClassIdentity as String,
                                          kSecAttrKeyClass as String: kSecAttrKeyClassPrivate as String,
                                          kSecMatchLimit as String : kSecMatchLimitAll as String,
                                          kSecReturnRef as String : true,
                                          kSecAttrApplicationLabel as String : digestData ]
        let err = SecItemCopyMatching(query, &out)
        guard err == errSecSuccess else {
            return nil
        }
        let identities = out! as! [SecIdentity]
        return identities
    }
    
    var privateKey: SecKey? {
        var privKey : SecKey?
        guard SecIdentityCopyPrivateKey(self, &privKey) == errSecSuccess else {
            return nil
        }
        return privKey
    }

}