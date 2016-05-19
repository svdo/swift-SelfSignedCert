//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Quick
import Nimble
@testable import SelfSignedCert

class SecKey_KeyDataTests: QuickSpec {

    override func spec() {
        
        it("can get public key data") {
            expect { Void->Void in
                let (_, pub) = try SecKey.generateKeyPair(ofSize: 512)
                let keyData = pub.keyData
                expect(keyData.count) > 0
            }.toNot(throwError())
        }
        
        xit("cannot get private key data") {
            expect { Void->Void in
                let (priv, _) = try SecKey.generateKeyPair(ofSize: 512)
                let keyData = priv.keyData
                try NSData(bytes:keyData).writeToFile("/tmp/privkeydata.bin", options: .AtomicWrite)
                expect(keyData.count) == 0
            }.toNot(throwError())
        }
        
    }
    
}
