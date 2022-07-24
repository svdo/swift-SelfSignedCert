//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import XCTest
import CryptoKit

import Quick
import Nimble
import IDZSwiftCommonCrypto
@testable import SelfSignedCert

func generateKeyPair() throws -> (SecKey, SecKey) {
    let pubKeyAttrs = [ kSecAttrIsPermanent as String: false ]
    let privKeyAttrs = [ kSecAttrIsPermanent as String: false ]
    let params: NSDictionary = [ kSecAttrKeyType as String : kSecAttrKeyTypeRSA as String,
                      kSecAttrKeySizeInBits as String : 2048,
                      kSecPublicKeyAttrs as String : pubKeyAttrs,
                      kSecPrivateKeyAttrs as String : privKeyAttrs ]

    var error: Unmanaged<CFError>?
    let privKey = SecKeyCreateRandomKey(params, &error)
    if let error = error {
        throw error.takeRetainedValue()
    }

    let pubKey = SecKeyCopyPublicKey(privKey!)!
    return (privKey!, pubKey)
}

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
                pubKey = try generateKeyPair().1
            }
            catch {
                print(error.localizedDescription)
                fatalError()
            }
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
                let pubKeyPath = Bundle.module.path(forResource:"pubkey", ofType: "bin")
                let nsData = NSData(contentsOfFile: pubKeyPath!)!
                return (nsData as Data).bytes
            }

            let certDataPath = Bundle.module.path(forResource: "certdata", ofType: "der")
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
            let encoded = certReq.toDER()
            // TODO: It seems that we have SecKey.keyData is nil
            expect(encoded?.count) == 444 /* same as previous test */
        }

        it("Can sign") {
            expect { () -> Void in
                let (privKey, pubKey) = try generateKeyPair()
                let certReq = CertificateRequest(forPublicKey: pubKey, subjectCommonName: "Test Name", subjectEmailAddress: "test@example.com", keyUsage: [.DigitalSignature, .DataEncipherment])
                let signedBytes = certReq.selfSign(withPrivateKey: privKey)!
                let signedData = Data(signedBytes)
                let signedCert = SecCertificateCreateWithData(nil, signedData as CFData)
                expect(signedCert).toNot(beNil())
                guard signedCert != nil else { return }
                let subjectSummary = SecCertificateCopySubjectSummary(signedCert!)
                expect(subjectSummary).toNot(beNil())
                expect(subjectSummary! as String) == "Test Name"
//
//                /*
//                 * The remainder of this test shows how the keychain is used to retrieve the SecIdentity that belongs to the signed certificate.
//                 * This is not very well documented, and there was some trial and error involved, so let's make sure that this keeps working
//                 * the way we expect it to.
//                 */
//
//                /* the identity is not available yet */
//                var identity = SecIdentity.find(withPublicKey:pubKey)
//                expect(identity).to(beNil())
//
//                /* store in keychain */
//                let dict : [NSString:AnyObject] = [
//                    kSecClass as NSString: kSecClassCertificate as NSString,
//                    kSecValueRef as NSString : signedCert!]
//                let osresult = SecItemAdd(dict as CFDictionary, nil)
//                expect(osresult) == errSecSuccess
//
//                /* now we can retrieve the identity */
//                identity = SecIdentity.find(withPublicKey:pubKey)
//                expect(identity).toNot(beNil())
//
//                /* verify: same private key */
//                var identityPrivateKey : SecKey?
//                expect(SecIdentityCopyPrivateKey(identity!, &identityPrivateKey)) == errSecSuccess
//                expect(identityPrivateKey!.keyData) == privKey.keyData
//
//                /* verify: same certificate */
//                var identityCertificate : SecCertificate?
//                expect(SecIdentityCopyCertificate(identity!, &identityCertificate)) == errSecSuccess
//                let identityCertificateData : Data = SecCertificateCopyData(identityCertificate!) as Data
//                let expectedCertificateData : Data = SecCertificateCopyData(signedCert!) as Data
//                expect(identityCertificateData.bytes) == expectedCertificateData.bytes
//
//                /* verify: same public key */
//                var trust:SecTrust?
//                let policy = SecPolicyCreateBasicX509();
//                expect(SecTrustCreateWithCertificates(identityCertificate!, policy, &trust)) == errSecSuccess
//                let identityCertificatePublicKey = SecTrustCopyPublicKey(trust!)
//                expect(identityCertificatePublicKey!.keyData) == pubKey.keyData
//
//                /* verify: signing with retrieved key gives same result */
//                let signedBytes2 = certReq.selfSign(withPrivateKey: identityPrivateKey!)
//                expect(signedBytes) == signedBytes2
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

final class GenCertTests: XCTestCase {
    func testTBSCert() {
        let serioNo = UInt64(Date.timeIntervalSinceReferenceDate * 1000)
        let issuer = Certificate.Name(commonName: "Gika")
        let validity = Certificate.Validity(notBefore: Date())

//        let privateKey = P256.Signing.PrivateKey()
        let privateKey = try! P256.Signing.PrivateKey(pemRepresentation: """
            -----BEGIN EC PRIVATE KEY-----
            MHcCAQEEIFs4s4/t2T2IXS+ugL2+azsZxk+FF8YF5M10qOya+JSSoAoGCCqGSM49
            AwEHoUQDQgAEukAEYEOAWhT+VEdOnQx1jTYtFr+X9/AUwv7JQXH2KR2YmWrXquOA
            mT51cAdD1yVlWIwNde55owIMJLrNiKdOnA==
            -----END EC PRIVATE KEY-----
            """)
        let subjectPublicKeyInfo = Certificate.SubjectPublicKeyInfo.p256(privateKey.publicKey)

        let tbsCert = Certificate.TBSCertificate(
            version: .v3,
            serialNo: serioNo,
            signature: .ecdsaWithSHA256,
            issuer: issuer,
            validity: validity,
            subject: issuer,
            subjectPublicKeyInfo: subjectPublicKeyInfo)

        let toSign = Data(tbsCert.toDER())
//        var sha256 = SHA256()
//        sha256.update(data: toSign)
//        let digest = sha256.finalize()
        let signature = try! privateKey.signature(for: toSign)

        let cert = Certificate(
            tbsCertificate: tbsCert,
            signatureValue: .init(data: signature.derRepresentation))

        print(Data(cert.toDER()).base64EncodedString())
    }

    func testSignature() {
        let privateKey = try! P256.Signing.PrivateKey(pemRepresentation: """
            -----BEGIN EC PRIVATE KEY-----
            MHcCAQEEIFs4s4/t2T2IXS+ugL2+azsZxk+FF8YF5M10qOya+JSSoAoGCCqGSM49
            AwEHoUQDQgAEukAEYEOAWhT+VEdOnQx1jTYtFr+X9/AUwv7JQXH2KR2YmWrXquOA
            mT51cAdD1yVlWIwNde55owIMJLrNiKdOnA==
            -----END EC PRIVATE KEY-----
            """)

        let text = "Hello\n"
        var sha256 = SHA256()
        sha256.update(data: text.data(using: .utf8)!)
        let digest = sha256.finalize()
        let signature = try! privateKey.signature(for: digest)

        print(signature.derRepresentation.base64EncodedString())
    }

    func testVerify() {
        let privateKey = try! P256.Signing.PrivateKey(pemRepresentation: """
            -----BEGIN EC PRIVATE KEY-----
            MHcCAQEEIFs4s4/t2T2IXS+ugL2+azsZxk+FF8YF5M10qOya+JSSoAoGCCqGSM49
            AwEHoUQDQgAEukAEYEOAWhT+VEdOnQx1jTYtFr+X9/AUwv7JQXH2KR2YmWrXquOA
            mT51cAdD1yVlWIwNde55owIMJLrNiKdOnA==
            -----END EC PRIVATE KEY-----
            """)
        let publicKey = privateKey.publicKey
        let signatureRaw = Data(base64Encoded: "MEUCIQCiDyOzYRQm6EaKj+WSvcUdQOrsmM1rXHDpoYZ3JHhhXwIgeHItvbFUq1iBxtwkFvqf/hfb4acugthtzfYNV9rxM+4=".data(using: .utf8)!)!
        let text = "Hello\n"
        var sha256 = SHA256()
        sha256.update(data: text.data(using: .utf8)!)
        let digest = sha256.finalize()
        let signature = try! P256.Signing.ECDSASignature(derRepresentation: signatureRaw)
        print(publicKey.isValidSignature(signature, for: digest))
    }
}

// public key:
// sign 304402205a3ec0f931f3b58ce4dcc11fd24f1142c0c9172eebb420b80b18c4fb9dbfce8502202477a367662838e3720f17e4123e0adb8b86142c83cc19557e30781711f077da

func dataWithHexString(hex: String) -> Data {
    var hex = hex
    var data = Data()
    while(hex.count > 0) {
        let subIndex = hex.index(hex.startIndex, offsetBy: 2)
        let c = String(hex[..<subIndex])
        hex = String(hex[subIndex...])
        var ch: UInt32 = 0
        Scanner(string: c).scanHexInt32(&ch)
        var char = UInt8(ch)
        data.append(&char, count: 1)
    }
    return data
}
