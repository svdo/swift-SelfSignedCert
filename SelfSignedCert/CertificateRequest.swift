//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import Security

/**
 * Option set used for specifying key usage in certificate requests.
 */
struct KeyUsage : OptionSet {
    let rawValue:  UInt16
    init(rawValue: UInt16) { self.rawValue = rawValue }
    
    static let DigitalSignature   = KeyUsage(rawValue: 0x80)
    static let NonRepudiation     = KeyUsage(rawValue: 0x40)
    static let KeyEncipherment    = KeyUsage(rawValue: 0x20)
    static let DataEncipherment   = KeyUsage(rawValue: 0x10)
    static let KeyAgreement       = KeyUsage(rawValue: 0x08)
    static let KeyCertSign        = KeyUsage(rawValue: 0x04)
    static let CRLSign            = KeyUsage(rawValue: 0x02)
    static let EncipherOnly       = KeyUsage(rawValue: 0x01)
    static let DecipherOnly       = KeyUsage(rawValue: 0x100)
    static let Unspecified        = KeyUsage(rawValue: 0xFFFF)        // Returned if key-usage extension is not present
}

func ==(lhs: KeyUsage, rhs: KeyUsage) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

/**
 * Represents a certificate request.
 */
struct CertificateRequest {
    var publicKey : SecKey
    var subjectCommonName: String
    var subjectEmailAddress: String
    var serialNumber: UInt64
    var validFrom: Date
    var validTo: Date
    var publicKeyDerEncoder: ((SecKey) -> [UInt8]?)?
    var keyUsage: KeyUsage
    
    init(forPublicKey key:SecKey, subjectCommonName:String, subjectEmailAddress:String, keyUsage:KeyUsage,
                      validFrom:Date? = nil, validTo:Date? = nil, serialNumber:UInt64? = nil) {
        self.publicKey = key
        self.subjectCommonName = subjectCommonName
        self.subjectEmailAddress = subjectEmailAddress
        if let from = validFrom {
            self.validFrom = from
        }
        else {
            self.validFrom = Date()
        }
        if let to = validTo {
            self.validTo = to
        }
        else {
            self.validTo = self.validFrom.addingTimeInterval(365*24*3600)
        }
        
        if let serial = serialNumber {
            self.serialNumber = serial
        }
        else {
            self.serialNumber = UInt64(CFAbsoluteTimeGetCurrent() * 1000)
        }
        self.keyUsage = keyUsage
        
        publicKeyDerEncoder = encodePublicKey
    }
    
    func encodePublicKey(_ key:SecKey) -> [UInt8]? {
        guard let data = SecKeyCopyExternalRepresentation(key, nil) as? Data else {
            return nil
        }
        return data.bytes
    }
    
    func selfSign(withPrivateKey key:SecKey) -> [UInt8]? {
        guard let info = self.info(usingSubjectAsIssuer:true) else {
            return nil
        }

        let dataToSign = info.toDER()
        guard let signedData = key.sign(data:dataToSign) else {
            return nil
        }
        let signature = BitString(data: Data(signedData))
        
        let signedInfo: NSArray = [ info, [OID.rsaWithSHA1AlgorithmID, NSNull()], signature]
        return signedInfo.toDER()
    }
}

extension CertificateRequest {
    func info(usingSubjectAsIssuer: Bool = false) -> NSArray? {
        precondition(publicKeyDerEncoder != nil)
        
        let empty = NSNull()
        let version = ASN1Object(
            tag:0, tagClass:2, components:[
                NSNumber(value: 3 /*kCertRequestVersionNumber*/ - 1 )
            ]
        )
        guard let bytes = publicKeyDerEncoder?(publicKey) else {
            return nil
        }
        let encodedPubKey = Data(bytes)
        let pubKeyBitStringArray : NSArray = [ [OID.rsaAlgorithmID, empty], BitString(data:encodedPubKey) ]
        let subject = CertificateName()
        subject.commonName = subjectCommonName
        subject.emailAddress = subjectEmailAddress
        let ext = ASN1Object(tag: 3, tagClass: 2, components: [extensions() as NSObject])
        let subjectComponents = subject.components
        let info : NSArray = [
            version, NSNumber(value: serialNumber as UInt64), [ OID.rsaAlgorithmID ], usingSubjectAsIssuer ? subjectComponents : [], [validFrom, validTo],
            subjectComponents, pubKeyBitStringArray, ext
        ]
        return info
    }
    
    func toDER() -> [UInt8]? {
        return info()?.toDER()
    }
    
    func extensions() -> [NSArray] {
        var extensions = [NSArray]()
        
        let keyUsageMask: UInt16 = keyUsage.rawValue
        if keyUsageMask != KeyUsage.Unspecified.rawValue {
            var bytes: [UInt8] = [0,0]
            bytes[0] = UInt8(keyUsageMask & 0xff)
            bytes[1] = UInt8(keyUsageMask >> 8)
            let length = 1 + ((bytes[1] != 0) ? 1 : 0)
            let data = Data(bytes: bytes, count: length)
            let bitString = BitString(data:data)
            let encodedBitString = bitString.toDER()
            extensions.append([OID.keyUsageOID, true/*critical*/, Data(encodedBitString)])
        }
        
        return extensions
    }
}
