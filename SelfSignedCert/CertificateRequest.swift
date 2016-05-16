//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import Security

enum KeyUsage {
    case DigitalSignature
    case DataEncipherment
}

struct CertificateRequest {
    var publicKey : SecKey
    var subjectCommonName: String
    var subjectEmailAddress: String
    var keyUsage: [KeyUsage]
    var serialNumber: UInt64
    var validFrom: NSDate
    var validTo: NSDate
    var publicKeyDerEncoder: (SecKey -> NSData)?
    
    init(forPublicKey key:SecKey, subjectCommonName:String, subjectEmailAddress:String, keyUsage:[KeyUsage],
                      validFrom:NSDate? = nil, validTo:NSDate? = nil, serialNumber:UInt64? = nil) {
        self.publicKey = key
        self.subjectCommonName = subjectCommonName
        self.subjectEmailAddress = subjectEmailAddress
        self.keyUsage = keyUsage
        if let from = validFrom {
            self.validFrom = from
        }
        else {
            self.validFrom = NSDate()
        }
        if let to = validTo {
            self.validTo = to
        }
        else {
            self.validTo = self.validFrom.dateByAddingTimeInterval(365*24*3600)
        }
        
        if let serial = serialNumber {
            self.serialNumber = serial
        }
        else {
            self.serialNumber = UInt64(CFAbsoluteTimeGetCurrent() * 1000)
        }
    }
    
    func sign(withPrivateKey key:SecKey) throws -> SecCertificate {
        // data = DER encoded self
        // key.sign(data) -> signedData
        // SecCertificateCreateWithData(signedData) -> SecCertificate
        throw NSError(domain:"xx", code: 1, userInfo: nil)
    }
}

extension CertificateRequest {
    func toDER() -> [UInt8] {
        /*
         id empty = [NSNull null];
         id version = [[MYASN1Object alloc] initWithTag: 0 ofClass: 2 components: @[ @(kCertRequestVersionNumber - 1) ]];
         id extensions = [[MYASN1Object alloc] initWithTag:3 ofClass:2 components: @[$marray()]];
         NSArray *root = $array( $marray(version,
                                         empty,       // serial #
                                         @[kRSAAlgorithmID],
                                         $marray(),
                                         $marray(empty, empty),
                                         $marray(),
                                         @[ @[kRSAAlgorithmID, empty],
                                            [MYBitString bitStringWithData: publicKey.keyData]
                                         ],
                                         extensions) );

 */
        precondition(publicKeyDerEncoder != nil)
        
        let empty = NSNull()
        let version = ASN1Object(tag:0, tagClass:2, components:[3/*kCertRequestVersionNumber*/-1])
        let encodedPubKey = publicKeyDerEncoder!(publicKey)
        let pubKeyBitStringArray : NSArray = [ [OID.rsaAlgorithmID, empty], BitString(data:encodedPubKey) ]
        let subject = CertificateName()
        subject.commonName = subjectCommonName
        subject.emailAddress = subjectEmailAddress
        let info : NSArray = [
                version, NSNumber(unsignedLongLong:serialNumber), [ OID.rsaAlgorithmID ], [], [validFrom, validTo], subject.components
                , pubKeyBitStringArray// todo , extensions
            ]
        
        return info.toDER()
    }
}
