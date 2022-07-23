// SelfSignedCert
//
// Copyright © 2022 Minsheng Liu. All rights reserved.
// Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation
import SwiftBytes

enum DERTag: UInt8 {
    case boolean = 1
    case integer = 2
    case bitString = 3
    case octetString = 4
    case objectIdentifier = 6
    case utf8String = 12
    case printableString = 19
    case sequence = 16
    case `set` = 17
    // According to Wikipedia, this should be 22 instead of 20.
    // However, the original code from @svdo uses 20, and so is the test fixtures.
    // TODO: Figure out whether we should use 20 or 22.
    case ia5String = 20 // 22
    case generalizedTime = 24
}

enum DERTagClass: UInt8 {
    case universal = 0
    case application = 1
    case contextSpecific = 2
    case `private` = 3
}

enum DERPrimitivity: UInt8 {
    case primitive = 0
    case construction = 1
}

struct DERHeader: Equatable {
    var tag: DERTag
    var tagClass: DERTagClass = .universal
    var primitivity: DERPrimitivity = .primitive
    var byteCount: Int
}

private extension DERHeader {
    var headerByteCount: Int {
        var base = 2
        // Here we assume the additional byte can hold the tag completely.
        if tag.rawValue >= 0b11111 {
            base += 1
        }
        if byteCount > 0x7F {
            base += Int.bitWidth / 8 - byteCount.leadingZeroBitCount / 8
        }
        return base
    }

    func encodeDER(to bytes: inout [UInt8]) {
        let identifier: UInt8 =
            (tagClass.rawValue << 6) +
            (primitivity.rawValue << 5) +
            min(tag.rawValue, 0b11111)
        bytes.append(identifier)

        if tag.rawValue >= 0b11111 {
            assert(tag.rawValue.leadingZeroBitCount > 0)
            bytes.append(tag.rawValue)
        }

        if byteCount <= 0x7F {
            bytes.append(UInt8(byteCount))
            return
        }

        let lengthByteCount = Int.bitWidth / 8 - byteCount.leadingZeroBitCount / 8
        bytes.append(0x80 + UInt8(lengthByteCount))
        let lengthBytes = UInt64(byteCount).bigEndianBytes.drop { $0 == 0 }
        bytes.append(contentsOf: lengthBytes)
    }
}

struct DERBuilder {
    private(set) var bytes: [UInt8] = []

    mutating func appendHeader(_ header: DERHeader) {
        header.encodeDER(to: &bytes)
    }

    mutating func append(_ byte: UInt8) {
        bytes.append(byte)
    }

    mutating func append<S: Sequence>(contentsOf data: S) where S.Element == UInt8 {
        bytes.append(contentsOf: data)
    }
}

protocol DEREncodable {
    var derHeader: DERHeader { get }
    func encodeDERContent(to builder: inout DERBuilder)
}

extension DEREncodable {
    func toDER() -> [UInt8] {
        var builder = DERBuilder()
        builder.appendHeader(derHeader)
        encodeDERContent(to: &builder)
        return builder.bytes
    }
}

extension Bool: DEREncodable {
    var derHeader: DERHeader {
        .init(tag: .boolean, byteCount: 1)
    }

    func encodeDERContent(to builder: inout DERBuilder) {
        builder.append(self ? 0xFF : 0)
    }
}

extension BinaryInteger {
    private var normalized: (bitPattern: UInt64, byteCount: Int) {
        guard Self.isSigned || UInt64(self).leadingZeroBitCount > 0 else {
            // In this case, we have to add a zero padding byte.
            return (UInt64(self), 9)
        }

        // Otherwise, the value can be held in Int64.
        let value = Int64(self)
        let isNegative = value < 0
        var bitPattern = UInt64(bitPattern: value)

        var detector = bitPattern
        if isNegative {
            detector = ~detector
        }
        // The spec requires the first 9 bits must not be the same.
        let bytesToDrop = max(detector.leadingZeroBitCount - 1, 0) / 8
        bitPattern <<= bytesToDrop * 8
        return (bitPattern, 8 - bytesToDrop)
    }

    var derHeader: DERHeader {
        .init(tag: .integer, byteCount: normalized.byteCount)
    }

    func encodeDERContent(to builder: inout DERBuilder) {
        let (bitPattern, byteCount) = normalized
        guard byteCount <= 8 else {
            builder.append(0)
            builder.append(contentsOf: UInt64(self).bigEndianBytes)
            return
        }
        builder.append(contentsOf: bitPattern.bigEndianBytes.prefix(byteCount))
    }
}

extension Int: DEREncodable {}
extension Int8: DEREncodable {}
extension Int16: DEREncodable {}
extension Int32: DEREncodable {}
extension Int64: DEREncodable {}
extension UInt: DEREncodable {}
extension UInt8: DEREncodable {}
extension UInt16: DEREncodable {}
extension UInt32: DEREncodable {}
extension UInt64: DEREncodable {}

extension BitString: DEREncodable {
    var derHeader: DERHeader {
        .init(tag: .bitString, byteCount: 1 + data.count)
    }

    func encodeDERContent(to builder: inout DERBuilder) {
        builder.append(UInt8(unusedBitCount))
        builder.append(contentsOf: data)
    }
}

extension Data: DEREncodable {
    var derHeader: DERHeader {
        .init(tag: .octetString, byteCount: count)
    }

    func encodeDERContent(to builder: inout DERBuilder) {
        builder.append(contentsOf: self)
    }
}

extension String: DEREncodable {
    private static let printableCharset: CharacterSet = {
        var charset = CharacterSet.alphanumerics
        charset.formUnion(.init(charactersIn: " '()+,-./:=?"))
        return charset
    }()

    private var tag: DERTag {
        for scalar in unicodeScalars {
            guard scalar.isASCII else { return .utf8String }
            guard Self.printableCharset.contains(scalar) else { return .ia5String }
        }
        return .printableString
    }

    var derHeader: DERHeader {
        .init(tag: tag, byteCount: utf8.count)
    }

    func encodeDERContent(to builder: inout DERBuilder) {
        builder.append(contentsOf: utf8)
    }
}

extension Date: DEREncodable {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.locale = Locale(identifier: "nb")
        return formatter
    }()

    var derHeader: DERHeader {
        assert(Self.formatter.string(from: self).utf8.count == 15)
        return .init(tag: .generalizedTime, byteCount: 15)
    }

    func encodeDERContent(to builder: inout DERBuilder) {
        builder.append(contentsOf: Self.formatter.string(from: self).utf8)
    }
}

@resultBuilder
struct DERListBuilder {
    static func buildExpression<T: DEREncodable>(_ value: T) -> [any DEREncodable] {
        [value]
    }

    static func buildBlock(_ components: [any DEREncodable]...) -> [any DEREncodable] {
        components.reduce(into: []) { $0 += $1 }
    }

    static func buildEither(first component: [any DEREncodable]) -> [any DEREncodable] {
        component
    }

    static func buildEither(second component: [any DEREncodable]) -> [any DEREncodable] {
        component
    }

    static func buildOptional(_ component: [DEREncodable]?) -> [DEREncodable] {
        component ?? []
    }

    static func buildPartialBlock(first: [any DEREncodable]) -> [any DEREncodable] {
        first
    }

    static func buildPartialBlock(accumulated: [any DEREncodable], next: [any DEREncodable]) -> [any DEREncodable] {
        accumulated + next
    }
}

struct DERList: DEREncodable {
    var tag: DERTag
    var list: [any DEREncodable]

    init(tag: DERTag, @DERListBuilder buildContent: () -> [any DEREncodable]) {
        self.tag = tag
        self.list = buildContent()
    }

    var derHeader: DERHeader {
        let byteCount = list.reduce(0) {
            let header = $1.derHeader
            return $0 + header.headerByteCount + header.byteCount
        }
        return .init(tag: tag, primitivity: .construction, byteCount: byteCount)
    }

    func encodeDERContent(to builder: inout DERBuilder) {
        for node in list {
            builder.appendHeader(node.derHeader)
            node.encodeDERContent(to: &builder)
        }
    }
}

//extension NSSet {
//    func toDER() -> [UInt8] {
//        var objects = [NSObject]()
//        for o in self {
//            objects.append(o as! NSObject)
//        }
//        return encodeCollection(objects, tag: 17, tagClass: 0)
//    }
//}


extension NSNull {
    func toDER() -> [UInt8] {
        return writeDER(tag: 5, constructed: false, bytes: [])
    }
}

extension UnsignedInteger {
    func encodeForDER() -> [UInt8] {
        var bytes : [UInt8] = SwiftBytes.bytes(UInt64(self)).removeLeadingZeros()
        if (bytes[0] & 0x80) == 0x80 {
            bytes = [0x00] + bytes
        }
        return bytes
    }
}

extension Sequence where Iterator.Element : BinaryInteger {
    func removeLeading(_ number:Iterator.Element) -> [Iterator.Element] {
        if self.min() == nil { return [] }
        var nonNumberFound = false
        let flat = self.compactMap { (elem:Iterator.Element) -> Iterator.Element? in
            if (elem == number && !nonNumberFound ) {
                return nil
            } else {
                nonNumberFound = true
                return elem
            }
        }
        return flat
    }

    func removeLeadingZeros() -> [Iterator.Element] {
        if self.min() == nil { return [] }
        let removedZeros = self.removeLeading(0)
        if removedZeros.count == 0 {
            return [0]
        }
        else {
            return removedZeros
        }
    }
}

extension ASN1Object {
    func toDER() -> [UInt8] {
        if let comps = self.components {
            return encodeCollection(comps, tag: self.tag, tagClass: self.tagClass)
        }
        else if let data = self.value {
            return writeDER(tag: self.tag, tagClass: self.tagClass, constructed: self.constructed, bytes: data)
        }
        else {
            assertionFailure("ASN1Object should have either components or value, but has neither")
            return []
        }
    }
}

extension NSArray {
    func toDER() -> [UInt8] {
        var objects = self as? [NSObject]
        if objects == nil {
            var copy = Array<NSObject>()
            for o in self {
                copy.append(o as! NSObject)
            }
            objects = copy
        }
        guard let collection = objects else {
            assertionFailure("Unable to endcode array")
            return []
        }
        return encodeCollection(collection, tag:16, tagClass: 0)
    }
}

extension NSSet {
    func toDER() -> [UInt8] {
        var objects = [NSObject]()
        for o in self {
            objects.append(o as! NSObject)
        }
        return encodeCollection(objects, tag: 17, tagClass: 0)
    }
}

extension NSNumber {
    func toDER() -> [UInt8] {
        // Special-case detection of booleans by pointer equality, because otherwise they appear
        // identical to 0 and 1:
        if (self===NSNumber(value: true) || self===NSNumber(value: false)) {
            let value:UInt8 = self===NSNumber(value: true) ?0xFF :0x00;
            return writeDER(tag: 1, constructed: false, bytes: [value])
        }
        
        guard let objcType = String(validatingUTF8: self.objCType) else {
            assertionFailure("Could not get objcType of NSNumber")
            return []
        }
        
        if (objcType.count == 1) {
            switch(objcType) {
            case "c", "i", "s", "l", "q":
                return self.int64Value.toDER()
            case "C", "I", "S", "L", "Q":
                return self.uint64Value.toDER()
            case "B":
                return self.boolValue.toDER()
            default:
                assertionFailure("Cannot DER encode NSNumber of type \(objcType)")
                return []
            }
        }
        
        assertionFailure("Cannot DER encode NSNumber of type \(objcType)")
        return []
    }
}

class NSAnyDEREncodable: NSObject {
    func toDER() -> [UInt8] {
        fatalError()
    }
}

final class NSDEREncodable<Value: DEREncodable>: NSAnyDEREncodable {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    override func toDER() -> [UInt8] {
        value.toDER()
    }
}

extension NSObject {
    func toDER_manualDispatch() -> [UInt8] {
        if let wrapper = self as? NSAnyDEREncodable {
            return wrapper.toDER()
        }

        if let d = self as? Date {
//            print("Date to DER: \(d)")
            let bytes = d.toDER()
//            print("Date to DER: \(d) -> \(bytes)")
            return bytes
        }
        else if let n = self as? NSNull {
//            print("NULL to DER")
            let bytes = n.toDER()
//            print("NULL to DER -> bytes")
            return bytes
        }
        else if let a = self as? NSArray {
//            print("Array to DER {")
            let bytes = a.toDER()
//            print("} -> \(bytes)")
            return bytes
        }
        else if let s = self as? NSSet {
//            print("Set to DER <")
            let bytes = s.toDER()
//            print("> -> \(bytes)")
            return bytes
        }
        else if let num = self as? NSNumber {
//            print("Number to DER: \(num)")
            let bytes = num.toDER()
//            print("Number to DER: \(num) -> \(bytes)")
            return bytes
        }
        else if let str = self as? NSString {
//            print("String to DER: \(str)")
            let bytes = (str as String).toDER()
//            print("String to DER: \(str) -> \(bytes)")
            return bytes
        }
        else if let asn1 = self as? ASN1Object {
//            print("ASN1Object to DER: \(asn1)")
            let bytes = asn1.toDER()
//            print("ASN1Object to DER: \(asn1) -> \(bytes)")
            return bytes
        }
        else if let oid = self as? OID {
//            print("OID to DER: \(oid)")
            let bytes = oid.toDER()
//            print("OID to DER: \(oid) -> \(bytes)")
            return bytes
        }
        else if let data = self as? Data {
//            print("Data to DER: \(data)")
            let bytes = data.toDER()
//            print("Data to DER: \(data) -> \(bytes)")
            return bytes
        }
        else {
            assertionFailure("toDER_manualDispatch not defined for object \(self)")
            return []
        }
    }
}
    
private func encodeCollection(_ collection:[NSObject], tag:UInt8, tagClass:UInt8) -> [UInt8] {
    var bytes = [UInt8]()
    for o in collection {
        bytes += o.toDER_manualDispatch()
    }
    return writeDER(tag: tag, tagClass: tagClass, constructed: true, bytes: bytes)
}

func writeDER(tag:UInt8, tagClass:UInt8 = 0, constructed:Bool, bytes:[UInt8]) -> [UInt8] {
    return writeDERHeader(tag: tag, tagClass: tagClass, constructed: constructed, length: UInt64(bytes.count)) + bytes
}

func writeDERHeader(tag:UInt8, tagClass:UInt8 = 0, constructed:Bool, length:UInt64) -> [UInt8] {
    let constructedBits : UInt8 = (constructed ? 1 : 0) << 5
    let classBits : UInt8 = tagClass << 6
    let headerByte1 : UInt8 = tag | constructedBits | classBits
    
    var headerByte2 : UInt8 = 0
    var headerExtraLength = [UInt8]()
    if length < 128 {
        headerByte2 = UInt8(length)
    }
    else {
        let l = UInt64(length)
        headerExtraLength = l.encodeForDER()
        headerByte2 = UInt8(headerExtraLength.count) | 0x80
    }
    return [headerByte1] + [headerByte2] + headerExtraLength
}
