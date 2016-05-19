//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

class BitString : NSObject {
    let data: [UInt8]
    let bitCount: UInt
    
    convenience init(data:NSData) {
        self.init(data: data.bytes)
    }
    
    init(data:[UInt8]) {
        self.data = data
        bitCount = UInt(data.count) * 8
    }
    
    override var description: String {
        return "\(self.dynamicType)\(data)"
    }
    
}
