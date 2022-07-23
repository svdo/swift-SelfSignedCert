// SelfSignedCert
//
// Copyright © 2022 Minsheng Liu. All rights reserved.

import Foundation

extension UInt64 {
    struct Bytes: Sequence {
        var storage: UInt64

        init(_ value: UInt64, bigEndian: Bool) {
            storage = bigEndian ? value.byteSwapped : value
        }

        struct Iterator: IteratorProtocol {
            var storage: UInt64
            var bytesLeft: Int

            mutating func next() -> UInt8? {
                guard bytesLeft > 0 else { return nil }
                bytesLeft -= 1
                let value = UInt8(storage & 0xFF)
                storage >>= 8
                return value
            }
        }

        func makeIterator() -> Iterator {
            .init(storage: storage, bytesLeft: 8)
        }
    }

    var bigEndianBytes: Bytes {
        .init(self, bigEndian: true)
    }

    var littleEndianBytes: Bytes {
        .init(self, bigEndian: false)
    }
}
