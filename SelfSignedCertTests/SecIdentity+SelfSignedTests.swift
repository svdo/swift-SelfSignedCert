//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Quick
import Nimble
@testable import SelfSignedCert

class SelfSignedCertTests: QuickSpec {

    override func spec() {

        it("Can create a self-signed identity") {
            var identity : SecIdentity?
            expect {
                identity = try SecIdentity.create()
            }.toNot(throwError())
            expect(identity).toNot(beNil())
        }

    }
    
}
