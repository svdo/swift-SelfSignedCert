//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Quick
import Nimble
import Security
@testable import SelfSignedCert

class SelfSignedCertTests: QuickSpec {

    override func spec() {

        it("Can create a self-signed identity") {
            let identity = SecIdentity.create(subjectCommonName: "test", subjectEmailAddress: "test@example.com")
            expect(identity).toNot(beNil())
        }

    }
    
}
