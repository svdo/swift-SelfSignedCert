import Foundation

public func bits(eightBits : UInt8) -> [Bool] {
    var result : [Bool] = []
    var mask = UInt8(0b10000000)
    for _ in 0..<8 {
        result.append((eightBits & mask) != 0)
        mask >>= 1
    }
    return result
}

public func nibbles(twoNibbles : UInt8) -> [UInt8] {
    let left = twoNibbles >> 4
    let right = twoNibbles & 0x0F
    return [left, right]
}

public func bytes(twoBytes : UInt16) -> [UInt8] {
    let left = UInt8(twoBytes >> 8)
    let right = UInt8(twoBytes & 0xFF)
    return [left, right]
}

public func bytes(fourBytes : UInt32) -> [UInt8] {
    let b0 = UInt8(fourBytes >> 24)
    let b1 = UInt8((fourBytes >> 16) & 0xFF)
    let b2 = UInt8((fourBytes >> 8) & 0xFF)
    let b3 = UInt8((fourBytes) & 0xFF)
    return [b0, b1, b2, b3]
}

public func bytes(eightBytes : UInt64) -> [UInt8] {
    let b0 = UInt8(eightBytes >> 56)
    let b1 = UInt8((eightBytes >> 48) & 0xFF)
    let b2 = UInt8((eightBytes >> 40) & 0xFF)
    let b3 = UInt8((eightBytes >> 32) & 0xFF)
    let b4 = UInt8((eightBytes >> 24) & 0xFF)
    let b5 = UInt8((eightBytes >> 16) & 0xFF)
    let b6 = UInt8((eightBytes >> 8) & 0xFF)
    let b7 = UInt8((eightBytes) & 0xFF)
    return [b0, b1, b2, b3, b4, b5, b6, b7]
}

public func concatenateBits(eightBits : Bool...)  -> UInt8 {
    return concatenateBits(eightBits)
}

public func concatenateBits(eightBits : [Bool]) -> UInt8 {
    var result : UInt8 = 0
    for bit in eightBits {
        result <<= 1
        if (bit) {
            result = result | 1
        }
    }
    return result;
}

public func concatenateNibbles(left : UInt8, _ right : UInt8) -> UInt8 {
    return left << 4 | right
}

public func concatenateBytes(left : UInt8, _ right : UInt8) -> UInt16 {
    return UInt16(left) << 8 | UInt16(right)
}

public func concatenateBytes(b0 : UInt8, _ b1 : UInt8, _ b2 : UInt8, _ b3 : UInt8) -> UInt32 {
    return UInt32(b0) << 24 | UInt32(b1) << 16 | UInt32(b2) << 8 | UInt32(b3)
}

public func concatenateBytes(
        b0 : UInt8, _ b1 : UInt8, _ b2 : UInt8, _ b3 : UInt8,
        _ b4 : UInt8, _ b5 : UInt8, _ b6 : UInt8, _ b7 : UInt8) -> UInt64 {
    var result : UInt64 = 0
    result = result | UInt64(b0) << 56
    result = result | UInt64(b1) << 48
    result = result | UInt64(b2) << 40
    result = result | UInt64(b3) << 32
    result = result | UInt64(b4) << 24
    result = result | UInt64(b5) << 16
    result = result | UInt64(b6) << 8
    result = result | UInt64(b7)
    return result
}

public func unsigned(byte: Int8) -> UInt8 {
    return UInt8(bitPattern: byte)
}

public func unsigned(int32: Int32) -> UInt32 {
    return UInt32(bitPattern: int32)
}

public func unsigned(int64: Int64) -> UInt64 {
    return UInt64(bitPattern: int64)
}

public func unsigned(bytes : [Int8]) -> [UInt8] {
    return bytes.map{ unsigned($0) }
}

public func signed(byte : UInt8) -> Int8 {
    return Int8(bitPattern: byte)
}

public func signed(uint32: UInt32) -> Int32 {
    return Int32(bitPattern: uint32)
}

public func signed(uint64: UInt64) -> Int64 {
    return Int64(bitPattern: uint64)
}

public func signed(bytes: [UInt8]) -> [Int8] {
    return bytes.map{ signed($0) }
}

extension NSData {

    public convenience init(bytes: [UInt8]) {
        self.init(bytes: bytes, length: Int(bytes.count))
    }

    public var bytes: [UInt8] {
        var result: [UInt8] = [UInt8](count: self.length, repeatedValue: 0)
        self.getBytes(&result, length:self.length)
        return result
    }

}