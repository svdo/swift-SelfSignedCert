//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

class OID : NSObject {
    let components: [UInt32]
    init(components: [UInt32]) {
        self.components = components
        super.init()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? OID else {
            return false
        }
        return components == other.components
    }
    
    override var hashValue: Int {
        var hash : Int = 0
        for i in components {
            hash = hash &+ Int(i)
        }
        return hash
    }

    override var description: String {
        var desc = "{"
        for c in components {
            desc += String(format: "%u ", c)
        }
        return desc + "}"
    }
}

extension OID {
    
    /** ALGORITHMS **/
    @nonobjc static let rsaAlgorithmID = OID(components:[1, 2, 840, 113549, 1, 1, 1])
    @nonobjc static let rsaWithSHA1AlgorithmID = OID(components:[1, 2, 840, 113549, 1, 1, 5])
    //    static let rsaWithSHA256AlgorithmID = OID(components:[1, 2, 840, 113549, 1, 1, 11])
    //    static let rsaWithMD5AlgorithmID = OID(components:[1, 2, 840, 113549, 1, 1, 4 ])
    //    static let rsaWithMD2AlgorithmID = OID(components:[1, 2, 840, 113549, 1, 1, 2])
    
    /** SUBJECT **/
    @nonobjc static let commonName = OID(components:[2, 5, 4, 3])
    //    static let givenNameOID = OID(components:[2, 5, 4, 42])
    //    static let surnameOID = OID(components:[2, 5, 4, 4])
    //    static let descriptionOID = OID(components:[2, 5, 4, 13])
    @nonobjc static let email = OID(components:[1, 2, 840, 113549, 1, 9, 1])
    
    /** USAGE **/
    //    static let basicConstraintsOID = OID(components:[2, 5, 29, 19])
    @nonobjc static let keyUsageOID = OID(components:[2, 5, 29, 15])
    //    static let extendedKeyUsageOID = OID(components:[2, 5, 29, 37])

    /** EXTENSIONS **/
    //    static let extendedKeyUsageServerAuthOID = OID(components:[1, 3, 6, 1, 5, 5, 7, 3, 1])
    //    static let extendedKeyUsageClientAuthOID = OID(components:[1, 3, 6, 1, 5, 5, 7, 3, 2])
    //    static let extendedKeyUsageCodeSigningOID = OID(components:[1, 3, 6, 1, 5, 5, 7, 3, 3])
    //    static let extendedKeyUsageEmailProtectionOID = OID(components:[1, 3, 6, 1, 5, 5, 7, 3, 4])
    //    static let extendedKeyUsageAnyOID = OID(components:[2, 5, 29, 37, 0])
    //    static let subjectAltNameOID = OID(components:[2, 5, 29, 17])
    
}
