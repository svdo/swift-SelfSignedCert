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
