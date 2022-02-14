//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import Security
import IDZSwiftCommonCrypto
import SecurityExtensions

extension SecIdentity
{

    /**
     * Create an identity using a self-signed certificate. This can fail in many ways, in which case it will return `nil`.
     * Since potential failures are non-recoverable, no details are provided in that case.
     *
     * - parameter ofSize: size of the keys, in bits; default is 3072
     * - parameter subjectCommonName: the common name of the subject of the self-signed certificate that is created
     * - parameter subjectEmailAddress: the email address of the subject of the self-signed certificate that is created
     * - returns: The created identity, or `nil` when there was an error.
     */
    public static func create(
        ofSize bits:UInt = 3072,
        subjectCommonName name:String,
        subjectEmailAddress email:String,
        validFrom:Date? = nil,
        validTo:Date? = nil
    ) -> SecIdentity? {
        let privKey: SecKey
        let pubKey: SecKey
        do {
            (privKey,pubKey) = try SecKey.generateKeyPair(ofSize: bits)
        }
        catch {
            return nil
        }
        let certRequest = CertificateRequest(
            forPublicKey:pubKey,
            subjectCommonName: name,
            subjectEmailAddress: email,
            keyUsage: [.DigitalSignature, .DataEncipherment],
            validFrom: validFrom,
            validTo: validTo
        )

        guard let signedBytes = certRequest.selfSign(withPrivateKey:privKey),
            let signedCert = SecCertificateCreateWithData(nil, Data(signedBytes) as CFData) else {
            return nil
        }
        
        let err = signedCert.storeInKeychain()
        guard err == errSecSuccess else {
            return nil
        }

        return findIdentity(forPrivateKey:privKey, publicKey:pubKey)
    }
    
    /**
     * Helper method that tries to load an identity from the keychain.
     *
     * - parameter forPrivateKey: the private key for which the identity should be searched
     * - parameter publicKey: the public key for which the identity should be searched; should match the private key
     * - returns: The identity if found, or `nil`.
     */
    private static func findIdentity(forPrivateKey privKey:SecKey, publicKey pubKey:SecKey) -> SecIdentity? {
        guard let identity = SecIdentity.find(withPublicKey:pubKey) else {
            return nil
        }
        
        // Since the way identities are stored in the keychain is sparsely documented at best,
        // double-check that this identity is the one we're looking for.
        guard let priv = identity.privateKey,
            let retrievedKeyData = priv.keyData,
            let originalKeyData = privKey.keyData, retrievedKeyData == originalKeyData else {
            return nil
        }
        
        return identity
    }
    
    /**
     * Finds the identity in the keychain based on the given public key.
     * The identity that is returned is the one that has the public key's digest
     * as label.
     *
     * - parameter withPublicKey: the public key that should be used to find the identity, based on it's digest
     * - returns: The identity if found, or `nil`.
     */
    public static func find(withPublicKey pubKey:SecKey) -> SecIdentity? {
        guard let identities = findAll(withPublicKey: pubKey), identities.count == 1 else {
            return nil
        }
        return identities[0]
    }

    /**
     * Finds all identities in the keychain based on the given public key.
     * The identities that are returned are the ones that have the public key's digest
     * as label. Because of the keychain query filters, and on current iOS versions,
     * this should return 0 or 1 identity, not more...
     *
     * - parameter withPublicKey: the public key that should be used to find the identity, based on it's digest
     * - returns: an array of identities if found, or `nil`
     */
    static func findAll(withPublicKey pubKey:SecKey) -> [SecIdentity]? {
        guard let keyData = pubKey.keyData else {
            return nil
        }
        let sha1 = Digest(algorithm: .sha1)
        _ = sha1.update(buffer: keyData, byteCount: keyData.count)
        let digest = sha1.final()
        let digestData = Data(digest)
        
        var out: AnyObject?
        let query : [NSString:AnyObject] = [kSecClass as NSString: kSecClassIdentity as NSString,
                                            kSecAttrKeyClass as NSString: kSecAttrKeyClassPrivate as NSString,
                                            kSecMatchLimit as NSString : kSecMatchLimitAll as NSString,
                                            kSecReturnRef as NSString : NSNumber(value: true),
                                            kSecAttrApplicationLabel as NSString : digestData as NSData ]
        let err = SecItemCopyMatching(query as CFDictionary, &out)
        guard err == errSecSuccess else {
            return nil
        }
        let identities = out! as! [SecIdentity]
        return identities
    }
    
}
