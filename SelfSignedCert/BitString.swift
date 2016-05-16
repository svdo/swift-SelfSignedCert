//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

class BitString : NSObject {
    let data: NSData
    let bitCount: UInt
    
    init(data:NSData) {
        self.data = data
        bitCount = UInt(data.length) * 8
    }
}
