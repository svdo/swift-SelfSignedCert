//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

struct BitString {
    var data: Data
    var unusedBitCount: Int = 0 {
        didSet {
            precondition((0..<8).contains(unusedBitCount))
            precondition(!data.isEmpty || unusedBitCount == 0)
        }
    }
}
//
//@available(*, deprecated, message: "Use Data instead.")
//class BitString : NSObject {
//    let data: [UInt8]
//    let bitCount: UInt
//
//    convenience init(data:Data) {
//        self.init(bytes: data.bytes)
//    }
//
//    init(bytes:[UInt8]) {
//        self.data = bytes
//        bitCount = UInt(data.count) * 8
//    }
//
//    override var description: String {
//        return "\(type(of: self))\(data)"
//    }
//
//}
