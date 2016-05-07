//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import SelfSignedCert

class KeyPairTests : QuickSpec {
    
    override func spec() {
        
        it("can generate key pair") {
            expect { Void->Void in
                let (privKey, pubKey) = try SecKey.generateKeyPair(ofSize: 2048)
                expect(privKey.blockSize) == 2048/8
                expect(pubKey.blockSize) == 2048/8
            }.toNot(throwError())
        }
        
    }
    
}
