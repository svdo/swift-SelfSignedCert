//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import SwiftBytes

extension NSNull {
    func toDER() -> [UInt8] {
        return writeDER(tag: 5, constructed: false, bytes: [])
    }
}

extension Bool {
    func toDER() -> [UInt8] {
        let value : UInt8 = self ? 0xFF : 0x00
        return writeDER(tag:1, constructed:false, bytes:[value])
    }
}

extension UnsignedIntegerType {
    func encodeForDER() -> [UInt8] {
        var bytes : [UInt8] = SwiftBytes.bytes(self.toUIntMax()).removeLeadingZeros()
        if (bytes[0] & 0x80) == 0x80 {
            bytes = [0x00] + bytes
        }
        return bytes
    }
    func toDER() -> [UInt8] {
        return writeDER(tag: 2, constructed: false, bytes: self.encodeForDER())
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
        if self.minElement() == nil { return [] }
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

extension String {
    func toDER() -> [UInt8] {
        let utf8Bytes = [UInt8](self.utf8)
        return writeDER(tag: 12, constructed: false, bytes: utf8Bytes)
    }
}

var berGeneralizedTimeFormatter: NSDateFormatter {
    let df = NSDateFormatter()
    df.dateFormat = "yyyyMMddHHmmss'Z'"
    df.timeZone = NSTimeZone(name: "GMT")
    return df
}

extension NSDate {
    func toDER() -> [UInt8] {
        let dateString = berGeneralizedTimeFormatter.stringFromDate(self)
        return writeDER(tag: 24, constructed: false, bytes: [UInt8](dateString.utf8))
    }
}

extension OID {
    func toDER() -> [UInt8] {
        var bytes = [UInt8]()
        var index = 0
        if (components.count >= 2 && components[0] <= 3 && components[1] < 40) {
            bytes.append(UInt8(components[0]) * 40 + UInt8(components[1]))
            index = 2
        }
        while index < components.count {
            var nonZeroAdded = false
            let component = components[index]
            for shift in 28.stride(through: 0, by: -7) {
                let byte = UInt8((component >> UInt32(shift)) & 0x7F)
                if (byte != 0 || nonZeroAdded) {
                    if (nonZeroAdded) {
                        bytes[bytes.count-1] |= 0x80
                    }
                    bytes.append(byte)
                    nonZeroAdded = true
                }
            }
            index = index + 1
        }
        return bytes
    }
}

struct DERSequence {
    let contentsGenerator:()->[UInt8]
    func toDER() -> [UInt8] {
        return writeDER(tag: 16, constructed: true, bytes: contentsGenerator())
    }
}

func writeDER(tag tag:UInt8, constructed:Bool, bytes:[UInt8]) -> [UInt8] {
    let constructedBits : UInt8 = (constructed ? 1 : 0) << 5
    let classBits : UInt8 = 0
    let headerByte1 : UInt8 = tag | constructedBits | classBits
    
    var headerByte2 : UInt8 = 0
    var headerExtraLength = [UInt8]()
    if bytes.count < 128 {
        headerByte2 = UInt8(bytes.count)
    }
    else {
        let l = UInt64(bytes.count)
        headerExtraLength = l.encodeForDER()
        headerByte2 = UInt8(headerExtraLength.count) | 0x80
    }
    return [headerByte1] + [headerByte2] + headerExtraLength + bytes
}
