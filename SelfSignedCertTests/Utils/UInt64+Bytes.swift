// SelfSignedCert
//
// Copyright © 2022 Minsheng Liu. All rights reserved.

import XCTest
@testable import SelfSignedCert

final class UInt64_BytesTests: XCTestCase {
    func testBasic() {
        XCTAssertEqual(Array((0 as UInt64).bigEndianBytes), [0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(Array((1 as UInt64).bigEndianBytes), [0, 0, 0, 0, 0, 0, 0, 1])
        XCTAssertEqual(Array((1 as UInt64).littleEndianBytes), [1, 0, 0, 0, 0, 0, 0, 0])

        let value = 0x1234_5678_9ABC_DEF0 as UInt64
        XCTAssertEqual(Array(value.bigEndianBytes), [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0])
        XCTAssertEqual(Array(value.littleEndianBytes), [0xF0, 0xDE, 0xBC, 0x9A, 0x78, 0x56, 0x34, 0x12])
    }
}
