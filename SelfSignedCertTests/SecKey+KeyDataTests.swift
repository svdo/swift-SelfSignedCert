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
                
    }
    
}
