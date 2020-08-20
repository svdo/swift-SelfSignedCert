//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import XCTest
import Quick
import Nimble
import IDZSwiftCommonCrypto
@testable import SelfSignedCert

class CertificateRequestTests: QuickSpec {

    var dateComponents: DateComponents {
        var dc = DateComponents()
        dc.year = 2016
        dc.month = 5
        dc.day = 14
        dc.hour = 16
        dc.minute = 32
        dc.second = 0
        dc.timeZone = TimeZone(secondsFromGMT: 0)
        return dc
    }
    var validFrom: Date {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        return calendar.date(from: dateComponents)!
    }
    var validTo: Date {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var dc = dateComponents
        dc.year = dc.year! + 1
        return calendar.date(from: dc)!
    }

    override func spec() {

        var pubKey: SecKey!
        
        beforeSuite {
            do {
                // doing this in `beforeSuite` instead of `beforeEach` makes the tests run faster...
                let (_, pub) = try SecKey.generateKeyPair(ofSize: 2048)
                pubKey = pub
            }
            catch {}
        }
        
        it("Can construct certificate request") {
            expect { () -> Void in
                let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
                expect(certReq.subjectCommonName) == "Test Name"
                expect(certReq.subjectEmailAddress) == "test@example.com"
                expect(certReq.keyUsage) == [.DigitalSignature, .DataEncipherment]
                expect(certReq.publicKey) === pubKey
            }.toNot(throwError())
        }
        
        it("Has default field values") {
            expect { () -> Void in
                let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
                expect(certReq.serialNumber) != 0
                expect(fabs(certReq.validFrom.timeIntervalSinceNow)).to(beLessThan(1))
                expect(fabs(certReq.validTo.timeIntervalSince(certReq.validFrom) - 365*24*3600)).to(beLessThan(1))
            }.toNot(throwError())
        }
        
        describe("key usage") {
            it("is stored correctly in extensions") {
                expect { () -> Void in
                    let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
                    let extensions = certReq.extensions()
                    expect(extensions.count) == 1
                    let ext = extensions[0]
                    expect(ext[0] as? OID) == OID.keyUsageOID
                    expect(ext[1] as? NSNumber) == NSNumber(value: true)
                    let bitsData = ext[2] as! Data
                    let bytes = bitsData.bytes
                    expect(bytes.count) == 4
                    expect(UInt16(bytes[3])) == KeyUsage.DigitalSignature.rawValue | KeyUsage.DataEncipherment.rawValue
                }.toNot(throwError())
            }
        }
        
        it("can be DER encoded with preserialized public key") {
            var certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "J.R. 'Bob' Dobbs", subjectEmailAddress: "bob@subgenius.org", keyUsage: [.DigitalSignature, .DataEncipherment], validFrom:self.validFrom, validTo:self.validTo, serialNumber:484929458750)
            certReq.publicKeyDerEncoder = { pubKey in
                let pubKeyPath = Bundle(for: self.classForCoder).path(forResource:"pubkey", ofType: "bin")
                let nsData = NSData(contentsOfFile: pubKeyPath!)!
                return (nsData as Data).bytes
            }
            
            let certDataPath = Bundle(for: self.classForCoder).path(forResource: "certdata", ofType: "der")
            let nsData = NSData(contentsOfFile: certDataPath!)!
            let expectedEncoded = (nsData as Data).bytes
            
            let encoded = certReq.toDER()
//            print(dumpData(encoded!, prefix:"", separator:""))
//            print("---")
//            print(dumpData(expectedEncoded, prefix:"", separator:""))
            expect(encoded) == expectedEncoded
        }

        it("can be DER encoded with public key") {
            let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "J.R. 'Bob' Dobbs", subjectEmailAddress: "bob@subgenius.org", keyUsage: [.DigitalSignature, .DataEncipherment], validFrom:self.validFrom, validTo:self.validTo, serialNumber:484929458750)
            let encoded = certReq.toDER()!
            expect(encoded.count) == 444 /* same as previous test */
        }
        
        it("Can sign") {
            expect { () -> Void in
                let (privKey, pubKey) = try SecKey.generateKeyPair(ofSize: 2048)
                let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
                let signedBytes = certReq.selfSign(withPrivateKey: privKey)!
                let signedData = Data(signedBytes)
                let signedCert = SecCertificateCreateWithData(nil, signedData as CFData)
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
                var identity = SecIdentity.find(withPublicKey:pubKey)
                expect(identity).to(beNil())
                
                /* store in keychain */
                let dict : [NSString:AnyObject] = [
                    kSecClass as NSString: kSecClassCertificate as NSString,
                    kSecValueRef as NSString : signedCert!]
                let osresult = SecItemAdd(dict as CFDictionary, nil)
                expect(osresult) == errSecSuccess
                
                /* now we can retrieve the identity */
                identity = SecIdentity.find(withPublicKey:pubKey)
                expect(identity).toNot(beNil())

                /* verify: same private key */
                var identityPrivateKey : SecKey?
                expect(SecIdentityCopyPrivateKey(identity!, &identityPrivateKey)) == errSecSuccess
                expect(identityPrivateKey!.keyData) == privKey.keyData
                
                /* verify: same certificate */
                var identityCertificate : SecCertificate?
                expect(SecIdentityCopyCertificate(identity!, &identityCertificate)) == errSecSuccess
                let identityCertificateData : Data = SecCertificateCopyData(identityCertificate!) as Data
                let expectedCertificateData : Data = SecCertificateCopyData(signedCert!) as Data
                expect(identityCertificateData.bytes) == expectedCertificateData.bytes
                
                /* verify: same public key */
                var trust:SecTrust?
                let policy = SecPolicyCreateBasicX509();
                expect(SecTrustCreateWithCertificates(identityCertificate!, policy, &trust)) == errSecSuccess
                let identityCertificatePublicKey = SecTrustCopyPublicKey(trust!)
                expect(identityCertificatePublicKey!.keyData) == pubKey.keyData
                
                /* verify: signing with retrieved key gives same result */
                let signedBytes2 = certReq.selfSign(withPrivateKey: identityPrivateKey!)
                expect(signedBytes) == signedBytes2
            }.toNot(throwError())
        }
    
    }
}

private func dumpData(_ data:[UInt8], prefix:String = "0x", separator:String = " ") -> String {
    var str = ""
    for b in data {
        if str.count > 0 {
            str += separator
        }
        str += prefix + String(format: "%.2x", b)
    }
    return str
}
