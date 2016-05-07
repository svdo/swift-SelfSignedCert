//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import Quick
import Nimble
import SwiftBytes
@testable import SelfSignedCert

class DERTests : QuickSpec {
    
    override func spec() {
        
        describe("DER encoding") {
            it("can encode booleans") {
                expect(true.toDER()) == [0x01,0x01,0xFF]
                expect(false.toDER()) == [0x01,0x01,0x00]
            }
            
            it("can encode integers") {
                expect(0.toDER()) == [0x02,0x01,0x00]
                expect(1.toDER()) == [0x02,0x01,0x01]
                expect((-1).toDER()) == [0x02,0x01,0xFF]
                expect(72.toDER()) == [0x02,0x01,0x48]
                expect((-128).toDER()) == [0x02,0x01,0x80]
                expect(128.toDER()) == [0x02,0x02,0x00,0x80]
                expect(255.toDER()) == [0x02,0x02,0x00,0xFF]
                expect((-256).toDER()) == [0x02,0x02,0xFF,0x00]
                expect(12345.toDER()) == [0x02,0x02,0x30,0x39]
                expect((-12345).toDER()) == [0x02,0x02,0xCF,0xC7]
                expect(123456789.toDER()) == [0x02,0x04,0x07,0x5B,0xCD,0x15]
                expect((-123456789).toDER()) == [0x02,0x04,0xF8,0xA4,0x32,0xEB]
            }
            
            it("can encode strings") {
                expect("hello".toDER()) == [0x0c, 0x05, 0x68, 0x65, 0x6c, 0x6c, 0x6f]
                expect("thérè".toDER()) == [0x0C, 0x07, 0x74, 0x68, 0xC3, 0xA9, 0x72, 0xC3, 0xA8]
            }
            
            it("can encode dates") {
                expect(NSDate(timeIntervalSinceReferenceDate: 265336576).toDER()) == [0x18, 0x0F] + [UInt8]("20090530003616Z".utf8)
            }
        }
        
        describe("Leading zeros") {
            it ("can remove leading zeros") {
                expect([UInt8]().removeLeadingZeros()) == []
                expect([0].removeLeadingZeros()) == [0]
                expect([1].removeLeadingZeros()) == [1]
                expect([0,0].removeLeadingZeros()) == [0]
                expect([1,0].removeLeadingZeros()) == [1,0]
                expect([0,1].removeLeadingZeros()) == [1]
                expect([1,1].removeLeadingZeros()) == [1,1]
            }
            
            it ("can compress leading 0xFF") {
                expect([UInt8]().ensureSingleLeadingOneBit()) == []
                expect([0].ensureSingleLeadingOneBit()) == [0xFF, 0]
                expect([1].ensureSingleLeadingOneBit()) == [0xFF, 1]
                expect([0xFF].ensureSingleLeadingOneBit()) == [0xFF]
                expect([0xFF,0xFF].ensureSingleLeadingOneBit()) == [0xFF]
                expect([0xFF,0xFF,0x00].ensureSingleLeadingOneBit()) == [0xFF,0x00]
                expect([0x80].ensureSingleLeadingOneBit()) == [0x80]
                expect([0x40].ensureSingleLeadingOneBit()) == [0xFF,0x40]
            }
        }
    }
    
}
