//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import XCTest
import Quick
import Nimble
import IDZSwiftCommonCrypto
@testable import SelfSignedCert

class CertificateRequestTests: QuickSpec {

    var dateComponents: NSDateComponents {
        let dc = NSDateComponents()
        dc.year = 2016
        dc.month = 5
        dc.day = 14
        dc.hour = 16
        dc.minute = 32
        dc.second = 0
        dc.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return dc
    }
    var validFrom: NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        return calendar!.dateFromComponents(dateComponents)!
    }
    var validTo: NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let dc = dateComponents
        dc.year = dc.year + 1
        return calendar!.dateFromComponents(dc)!
    }

    override func spec() {

        var pubKey: SecKey!
        
        beforeSuite { ()->() in
            do {
                // doing this in `beforeSuite` instead of `beforeEach` makes the tests run faster...
                let (_, pub) = try SecKey.generateKeyPair(ofSize: 2048)
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
        
        it("can be DER encoded with preserialized public key") {
            var certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "J.R. 'Bob' Dobbs", subjectEmailAddress: "bob@subgenius.org", keyUsage: [.DigitalSignature, .DataEncipherment], validFrom:self.validFrom, validTo:self.validTo, serialNumber:484929458750)
            certReq.publicKeyDerEncoder = { pubKey in
                let pubKeyPath = NSBundle(forClass: self.classForCoder).pathForResource("pubkey", ofType: "bin")
                return NSData(contentsOfFile: pubKeyPath!)!.bytes
            }
            
            let certDataPath = NSBundle(forClass: self.classForCoder).pathForResource("certdata", ofType: "der")
            let expectedEncoded = NSData(contentsOfFile: certDataPath!)!.bytes
            
            let encoded = certReq.toDER()
//            print(dumpData(encoded, prefix:"", separator:""))
            expect(encoded) == expectedEncoded
        }

        it("can be DER encoded with public key") {
            let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "J.R. 'Bob' Dobbs", subjectEmailAddress: "bob@subgenius.org", keyUsage: [.DigitalSignature, .DataEncipherment], validFrom:self.validFrom, validTo:self.validTo, serialNumber:484929458750)
            let encoded = certReq.toDER()
            expect(encoded.count) == 444 /* same as previous test */
        }
        
        it("Can sign") {
            expect { Void->Void in
                let (privKey, pubKey) = try SecKey.generateKeyPair(ofSize: 2048)
                let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
                let signedBytes = try certReq.selfSign(withPrivateKey: privKey)
                let signedData = NSData(bytes: signedBytes)
                let signedCert = SecCertificateCreateWithData(nil, signedData)
                expect(signedCert).toNot(beNil())
                let subjectSummary = SecCertificateCopySubjectSummary(signedCert!)
                expect(subjectSummary).toNot(beNil())
                expect(subjectSummary! as String) == "Test Name"

                /*
                 * The remainder of this test shows how the keychain is used to retrieve the SecIdentity that belongs to the signed certificate.
                 * This is not very well documented, and there was some trial and error involved, so let's make sure that this keeps working
                 * the way we expect it to.
                 */
                
                /* the identity is not available yet */
                var identity = SecIdentity.findFirst(withPublicKey:pubKey)
                expect(identity).to(beNil())
                
                /* store in keychain */
                let dict : [String:AnyObject] = [
                    kSecClass as String: kSecClassCertificate as String,
                    kSecValueRef as String : signedCert!]
                let osresult = SecItemAdd(dict, nil)
                expect(osresult) == errSecSuccess
                
                /* now we can retrieve the identity */
                identity = SecIdentity.findFirst(withPublicKey:pubKey)
                expect(identity).toNot(beNil())

                /* verify: same private key */
                var identityPrivateKey : SecKey?
                expect(SecIdentityCopyPrivateKey(identity!, &identityPrivateKey)) == errSecSuccess
                expect(identityPrivateKey!.keyData) == privKey.keyData
                
                /* verify: same certificate */
                var identityCertificate : SecCertificate?
                expect(SecIdentityCopyCertificate(identity!, &identityCertificate)) == errSecSuccess
                let identityCertificateData : NSData = SecCertificateCopyData(identityCertificate!)
                let expectedCertificateData : NSData = SecCertificateCopyData(signedCert!)
                expect(identityCertificateData.bytes) == expectedCertificateData.bytes
                
                /* verify: same public key */
                var trust:SecTrust?
                let policy = SecPolicyCreateBasicX509();
                expect(SecTrustCreateWithCertificates(identityCertificate!, policy, &trust)) == errSecSuccess
                let identityCertificatePublicKey = SecTrustCopyPublicKey(trust!)
                expect(identityCertificatePublicKey!.keyData) == pubKey.keyData
                
                /* verify: signing with retrieved key gives same result */
                let signedBytes2 = try certReq.selfSign(withPrivateKey: identityPrivateKey!)
                expect(signedBytes) == signedBytes2
            }.toNot(throwError())
        }
    
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
