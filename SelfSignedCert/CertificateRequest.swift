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
        let signature = NSDEREncodable(BitString(data: Data(signedData)))

        let signedInfo: NSArray = [ info, [
            NSDEREncodable(OID.rsaWithSHA1AlgorithmID),
            NSNull()], signature]
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
        let pubKeyBitStringArray : NSArray = [ [
            NSDEREncodable(OID.rsaAlgorithmID), empty
        ], NSDEREncodable(BitString(data:encodedPubKey)) ]
        var subject = CertificateName()
        subject.commonName = subjectCommonName
        subject.emailAddress = subjectEmailAddress
        let ext = ASN1Object(tag: 3, tagClass: 2, components: [extensions() as NSObject])
        let subjectComponents = NSDEREncodable(subject.components)
        let info : NSArray = [
            version, NSNumber(value: serialNumber as UInt64),
            [ NSDEREncodable(OID.rsaAlgorithmID) ],
            usingSubjectAsIssuer ? subjectComponents : [],
            [validFrom, validTo],
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
            let bitString = NSDEREncodable(BitString(data:data))
            let encodedBitString = bitString.toDER()
            extensions.append([
                NSDEREncodable(OID.keyUsageOID),
                true/*critical*/,
                Data(encodedBitString)])
        }
        
        return extensions
    }
}

/*
 <[48, 130, 1, 184,

 160, 3, 2, 1, 2, 2, 5, 112, 232, 12, 82, 62, 48, 11, 6, 9, 42, 134, 72, 134, 247, 13, 1, 1, 1, 48, 0,
 48, 34, 24, 15, 50, 48, 49, 54, 48, 53, 49, 52, 49, 54, 51, 50, 48, 48, 90, 24, 15, 50, 48, 49, 55, 48, 53, 49, 52, 49, 54, 51, 50, 48, 48, 90,

 48, 61, 49, 25, 48,

 23, 6, 3, 85, 4, 3, 19, 16, 74, 46, 82, 46, 32, 39, 66, 111, 98, 39, 32, 68, 111, 98, 98, 115, 49,

 32, 48,

 30, 6, 9, 42, 134, 72, 134, 247, 13, 1, 9, 1,

 20, 17, 98, 111, 98, 64, 115, 117, 98, 103, 101, 110, 105, 117, 115, 46, 111, 114, 103, 48, 130, 1, 34, 48, 13, 6, 9, 42, 134, 72, 134, 247, 13, 1, 1, 1, 5, 0, 3, 130, 1, 15, 0, 48, 130, 1, 10, 2, 130, 1, 1, 0, 150, 51, 145, 220, 25, 36, 60, 181, 154, 202, 243, 147, 145, 196, 187, 62, 238, 210, 151, 130, 41, 1, 215, 64, 28, 181, 105, 122, 64, 79, 222, 254, 181, 155, 55, 22, 49, 27, 46, 220, 107, 198, 188, 140, 234, 103, 156, 122, 197, 210,

 124, 92, 74, 133, 249, 220, 117, 215, 36, 74, 127, 228, 101, 219, 85, 248, 239, 225, 188, 104, 245, 200, 239, 142, 4, 253, 62, 114, 177, 75, 93, 189, 159,

 43, 37, 235, 127, 37, 246, 26, 88, 145, 107, 182, 199, 170, 6, 175, 70, 88, 246, 78, 132, 100, 208, 247, 69, 145, 63, 52, 205, 231, 171, 187, 203, 240, 103, 251, 100,

 112, 220, 79, 181, 183, 62, 31, 202, 207, 140, 200, 183, 233, 185, 6, 151, 156, 213, 122, 152, 116, 244, 57, 78, 30, 146, 139, 8, 239, 113, 100, 250, 219,

 41, 143, 76, 103, 246, 92, 160, 10, 221, 181, 98, 135, 25, 236, 235, 17, 102, 248, 117, 186, 206, 64, 232, 38, 130, 5, 18, 148, 46, 54, 229, 229, 86, 167,

 9, 121, 244, 41, 87, 48, 221, 25, 166, 241, 76, 130, 31, 206, 106, 8, 53, 132, 244, 165, 171, 66, 107, 50, 23, 173, 114, 88, 103, 47,

 248, 245, 234, 98, 145, 25, 119, 40, 213, 26, 69, 51, 45, 149, 101, 76, 212, 248, 245, 248, 124, 164, 68, 182, 100, 82, 100, 187, 4, 167, 37, 90, 87, 205, 185, 180, 213, 65, 242,
 39, 2, 3, 1, 0, 1, 163, 18, 48, 16, 48, 14, 6, 3, 85, 29, 15, 1, 1, 255, 4, 4, 3, 2, 0, 144]>

 , got
 <[48, 130, 1, 180, 160, 3, 2, 1, 2, 2, 5, 112, 232, 12, 82, 62, 48, 11, 6, 9, 42, 134, 72, 134, 247, 13, 1, 1, 1, 48, 0, 48, 34,
 24, 15, 50, 48, 49, 54, 48, 53, 49, 52, 49, 54, 51, 50, 48, 48, 90, 24, 15, 50, 48, 49, 55, 48, 53, 49, 52, 49, 54, 51, 50, 48, 48, 90,

 49, 57, 49,

 23, 6, 3, 85, 4, 3, 19, 16, 74, 46, 82, 46, 32, 39, 66, 111, 98, 39, 32, 68, 111, 98, 98, 115, 49,

 30, 6, 9, 42, 134, 72, 134, 247, 13, 1, 9, 1,

 20, 17, 98, 111, 98, 64, 115, 117, 98, 103, 101, 110, 105, 117, 115, 46, 111, 114, 103, 48, 130, 1, 34, 48, 13, 6, 9, 42, 134, 72, 134, 247, 13, 1, 1, 1, 5, 0, 3, 130, 1, 15, 0, 48, 130, 1, 10, 2, 130, 1, 1, 0, 150, 51, 145, 220, 25, 36, 60, 181, 154, 202, 243, 147, 145, 196, 187, 62, 238, 210, 151, 130, 41, 1, 215, 64, 28, 181, 105, 122, 64, 79, 222, 254, 181, 155, 55, 22, 49, 27, 46, 220, 107, 198, 188, 140, 234, 103, 156, 122, 197, 210,

 124, 92, 74, 133, 249, 220, 117, 215, 36, 74, 127, 228, 101, 219, 85, 248, 239, 225, 188, 104, 245, 200, 239, 142, 4, 253, 62, 114, 177, 75, 93, 189, 159,

 43, 37, 235, 127, 37, 246, 26, 88, 145, 107, 182, 199, 170, 6, 175, 70, 88, 246, 78, 132, 100, 208, 247, 69, 145, 63, 52, 205, 231, 171, 187, 203, 240, 103, 251, 100,

 112, 220, 79, 181, 183, 62, 31, 202, 207, 140, 200, 183, 233, 185, 6, 151, 156, 213, 122, 152, 116, 244, 57, 78, 30, 146, 139, 8, 239, 113, 100, 250, 219,

 41, 143, 76, 103, 246, 92, 160, 10, 221, 181, 98, 135, 25, 236, 235, 17, 102, 248, 117, 186, 206, 64, 232, 38, 130, 5, 18, 148, 46, 54, 229, 229, 86, 167,

 9, 121, 244, 41, 87, 48, 221, 25, 166, 241, 76, 130, 31, 206, 106, 8, 53, 132, 244, 165, 171, 66, 107, 50, 23, 173, 114, 88, 103, 47,

 248, 245, 234, 98, 145, 25, 119, 40, 213, 26, 69, 51, 45, 149, 101, 76, 212, 248, 245, 248, 124, 164, 68, 182, 100, 82, 100, 187, 4, 167, 37, 90, 87, 205, 185, 180, 213, 65, 242,
 39, 2, 3, 1, 0, 1, 163, 18, 48, 16, 48, 14, 6, 3, 85, 29, 15, 1, 1, 255, 4, 4, 3, 2, 0, 144]>
 */
