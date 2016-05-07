//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import Quick
import Nimble
import SwiftBytes
@testable import SelfSignedCert

class DERTests : QuickSpec {
    
    override func spec() {
        
        fit("can encode basic types") {
            expect(true.toDER()) == [0x01,0x01,0xFF]
            expect(false.toDER()) == [0x01,0x01,0x00]
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



extension Bool {
    func toDER() -> [UInt8] {
        let value : UInt8 = self ? 0xFF : 0x00
        return writeDER(tag:1, constructed:false, bytes:[value])
    }
}

extension UnsignedIntegerType {
    func toDER() -> [UInt8] {
        var bytes : [UInt8] = SwiftBytes.bytes(self.toUIntMax()).removeLeadingZeros()
        if (bytes[0] & 0x80) == 0x80 {
            bytes = [0x00] + bytes
        }
        return writeDER(tag: 2, constructed: false, bytes: bytes)
    }
}

extension IntegerType {
    func toDER() -> [UInt8] {
        if self >= 0 {
            return UInt64(self.toIntMax()).toDER()
        }
        else {
            let bitPattern = ~(-self.toIntMax()) + 1
            let twosComplement = UInt64(bitPattern:bitPattern)
            let bytes : [UInt8] = SwiftBytes.bytes(twosComplement).ensureSingleLeadingOneBit()
            //[ UInt8(self.toIntMax() & 0x000000FF) ]
            return writeDER(tag: 2, constructed: false, bytes: bytes)
        }
    }
}



extension SequenceType where Generator.Element:IntegerType {
    func removeLeading(number:Generator.Element) -> [Generator.Element] {
        if self.minElement() == nil { return [] }
        var nonNumberFound = false
        let flat = self.flatMap { (elem:Generator.Element) -> Generator.Element? in
            if (elem == number && !nonNumberFound ) {
                return nil
            } else {
                nonNumberFound = true
                return elem
            }
        }
        return flat
    }
    
    func removeLeadingZeros() -> [Generator.Element] {
        let removedZeros = self.removeLeading(0)
        if removedZeros.count == 0 {
            return [0]
        }
        else {
            return removedZeros
        }

    }
    
    func ensureSingleLeadingOneBit() -> [Generator.Element] {
        if self.minElement() == nil { return [] }
        let removedFF = self.removeLeading(0xFF)
        if removedFF.count == 0 {
            return [0xFF]
        }
        else if  removedFF[0] & 0x80 != 0x80 {
            return [0xFF] + removedFF
        }
        return removedFF
    }
}

func writeDER(tag tag:UInt8, constructed:Bool, bytes:[UInt8]) -> [UInt8] {
    let constructedBits : UInt8 = (constructed ? 1 : 0) << 5
    let classBits : UInt8 = 0
    let headerByte1 : UInt8 = tag | constructedBits | classBits
    let lengthBits : UInt8 = UInt8(bytes.count)
    let headerByte2 : UInt8 = lengthBits
    return [headerByte1, headerByte2] + bytes
}
