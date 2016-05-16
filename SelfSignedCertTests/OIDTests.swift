//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Quick
import Nimble
@testable import SelfSignedCert

class OIDTests: QuickSpec {
    
    override func spec() {
        
        it("supports equals") {
            let oid1 = OID(components: [1, 2, 3, 4])
            let oid2 = OID(components: [1, 2, 3, 4])
            expect(oid1) == oid2
        }
        
    }
}
