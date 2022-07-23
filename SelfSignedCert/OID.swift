// SelfSignedCert
//
// Copyright © 2022 Minsheng Liu. All rights reserved.
// Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

struct OID: Equatable, Hashable {
    let components: [Int]

    init(components: [Int]) {
        self.components = components
    }
}

extension OID: ExpressibleByArrayLiteral {
    init(arrayLiteral: Int...) {
        self.init(components: Array(arrayLiteral))
    }
}

extension OID: CustomStringConvertible {
    var description: String {
        components.map(\.description).joined(separator: ".")
    }
}

extension OID: DEREncodable {
    static func byteCount(for value: Int) -> Int {
        (value.bitWidth - value.leadingZeroBitCount + 7 - 1) / 7
    }

    static func bytes(for value: Int) -> [UInt8] {
        let byteCount = max(byteCount(for: value), 1)
        var bytes: [UInt8] = Array(repeating: 0x80, count: byteCount)
        bytes[bytes.count - 1] = 0
        var value = value
        for j in 0..<byteCount {
            let i = bytes.count - 1 - j
            bytes[i] |= UInt8(value & 0x7F)
            value >>= 7
        }
        return bytes
    }

    private var firstSubidentifier: Int {
        components[0] * 40 + components[1]
    }

    private var contentByteCount: Int {
        guard !components.isEmpty else { return 0 }
        return components[2...].reduce(Self.byteCount(for: firstSubidentifier)) {
            $0 + Self.byteCount(for: $1)
        }
    }

    var derHeader: DERHeader {
        .init(tag: .objectIdentifier, byteCount: contentByteCount)
    }

    func encodeDERContent(to builder: inout DERBuilder) {
        guard !components.isEmpty else { return }
        builder.append(contentsOf: Self.bytes(for: firstSubidentifier))
        for subidentifier in components[2...] {
            builder.append(contentsOf: Self.bytes(for: subidentifier))
        }
    }
}

extension OID {
    // MARK: Algorithms
    static let rsaAlgorithmID: Self = [1, 2, 840, 113549, 1, 1, 1]
    static let rsaWithSHA1AlgorithmID: Self = [1, 2, 840, 113549, 1, 1, 5]

    //    static let rsaWithSHA256AlgorithmID = OID(components:[1, 2, 840, 113549, 1, 1, 11])
    //    static let rsaWithMD5AlgorithmID = OID(components:[1, 2, 840, 113549, 1, 1, 4 ])
    //    static let rsaWithMD2AlgorithmID = OID(components:[1, 2, 840, 113549, 1, 1, 2])
    
    // MARK: Subject
    static let commonName: Self = [2, 5, 4, 3]
    //    static let givenNameOID = OID(components:[2, 5, 4, 42])
    //    static let surnameOID = OID(components:[2, 5, 4, 4])
    //    static let descriptionOID = OID(components:[2, 5, 4, 13])
    static let email: Self = [1, 2, 840, 113549, 1, 9, 1]
    
    // MARK: Usage
    //    static let basicConstraintsOID = OID(components:[2, 5, 29, 19])
    static let keyUsageOID: Self = [2, 5, 29, 15]
    //    static let extendedKeyUsageOID = OID(components:[2, 5, 29, 37])

    /** EXTENSIONS **/
    //    static let extendedKeyUsageServerAuthOID = OID(components:[1, 3, 6, 1, 5, 5, 7, 3, 1])
    //    static let extendedKeyUsageClientAuthOID = OID(components:[1, 3, 6, 1, 5, 5, 7, 3, 2])
    //    static let extendedKeyUsageCodeSigningOID = OID(components:[1, 3, 6, 1, 5, 5, 7, 3, 3])
    //    static let extendedKeyUsageEmailProtectionOID = OID(components:[1, 3, 6, 1, 5, 5, 7, 3, 4])
    //    static let extendedKeyUsageAnyOID = OID(components:[2, 5, 29, 37, 0])
    //    static let subjectAltNameOID = OID(components:[2, 5, 29, 17])
    
}
