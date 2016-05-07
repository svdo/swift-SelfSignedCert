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
    
    init(forPublicKey key:SecKey, subjectCommonName:String, subjectEmailAddress:String, keyUsage:[KeyUsage]) {
        self.publicKey = key
        self.subjectCommonName = subjectCommonName
        self.subjectEmailAddress = subjectEmailAddress
        self.keyUsage = keyUsage
        self.validFrom = NSDate()
        self.validTo = self.validFrom.dateByAddingTimeInterval(365*24*3600)
        
        serialNumber = UInt64(CFAbsoluteTimeGetCurrent() * 1000)
    }
    
    func sign(withPrivateKey key:SecKey) throws -> SecCertificate {
        // data = DER encoded self
        // key.sign(data) -> signedData
        // SecCertificateCreateWithData(signedData) -> SecCertificate
        throw NSError(domain:"xx", code: 1, userInfo: nil)
    }
}
