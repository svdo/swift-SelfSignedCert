//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import XCTest
import Quick
import Nimble
@testable import SelfSignedCert

class CertificateRequestTests: QuickSpec {

    override func spec() {

        var privKey: SecKey!
        var pubKey: SecKey!
        
        beforeSuite { ()->() in
            do {
                let (priv, pub) = try SecKey.generateKeyPair(ofSize: 2048)
                privKey = priv
                pubKey = pub
            }
            catch {}
        }
        
        it("Can construct certificate request") {
            expect { Void->Void in
                let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
                expect(certReq.subjectCommonName) == "Test Name"
                expect(certReq.subjectEmailAddress) == "test@example.com"
                expect(certReq.keyUsage) == [.DigitalSignature, .DataEncipherment]
                expect(certReq.publicKey) === pubKey
            }.toNot(throwError())
        }
        
        it("Has default field values") {
            expect { Void->Void in
                let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
                expect(certReq.serialNumber) != 0
                expect(fabs(certReq.validFrom.timeIntervalSinceNow)).to(beLessThan(1))
                expect(fabs(certReq.validTo.timeIntervalSinceDate(certReq.validFrom) - 365*24*3600)).to(beLessThan(1))
            }.toNot(throwError())
        }
        
        describe("key usage") {
            it("is stored correctly in extensions") {
                expect { Void->Void in
                    let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
                    let extensions = certReq.extensions()
                    expect(extensions.count) == 1
                    let ext = extensions[0]
                    expect(ext[0] as? OID) == OID.keyUsageOID
                    expect(ext[1] as? NSNumber) == NSNumber(bool: true)
                    let bitsData = ext[2] as! NSData
                    let bytes = bitsData.bytes
                    expect(bytes.count) == 4
                    expect(UInt16(bytes[3])) == KeyUsage.DigitalSignature.rawValue | KeyUsage.DataEncipherment.rawValue
                }.toNot(throwError())
            }
        }
        
        it("can be DER encoded") {
            let dc = NSDateComponents()
            dc.year = 2016
            dc.month = 5
            dc.day = 14
            dc.hour = 16
            dc.minute = 32
            dc.second = 0
            dc.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            let validFrom = calendar!.dateFromComponents(dc)
            dc.year = 2017
            let validTo = calendar!.dateFromComponents(dc)
            var certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "J.R. 'Bob' Dobbs", subjectEmailAddress: "bob@subgenius.org", keyUsage: [.DigitalSignature, .DataEncipherment], validFrom:validFrom, validTo:validTo, serialNumber:484929458750)
            certReq.publicKeyDerEncoder = { pubKey in
                let pubKeyPath = NSBundle(forClass: self.classForCoder).pathForResource("pubkey", ofType: "bin")
                return NSData(contentsOfFile: pubKeyPath!)!
            }
            
            let certDataPath = NSBundle(forClass: self.classForCoder).pathForResource("certdata", ofType: "der")
            let expectedEncoded = NSData(contentsOfFile: certDataPath!)!.bytes
            
            let encoded = certReq.toDER()
//            print(dumpData(encoded, prefix:"", separator:""))
            expect(encoded) == expectedEncoded
        }
        
//        it("Can sign") {
//            expect { Void->Void in
//                let (privKey, pubKey) = try SecKey.generateKeyPair(ofSize: 2048)
//                let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
//                let cert = try certReq.sign(withPrivateKey: privKey)
//                // store cert in keychain
//                // find the matching identity
//            }.toNot(throwError())
//        }
        
    }
}

private func dumpData(data:[UInt8], prefix:String = "0x", separator:String = " ") -> String {
    var str = ""
    for b in data {
        if str.characters.count > 0 {
            str += separator
        }
        str += prefix + String(format: "%.2x", b)
    }
    return str
}
