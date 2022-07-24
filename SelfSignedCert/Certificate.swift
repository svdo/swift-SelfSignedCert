// SelfSignedCert
//
// Copyright © 2022 Minsheng Liu. All rights reserved.

import Foundation
import CryptoKit

struct Certificate {
    var tbsCertificate: TBSCertificate
    var algorithm: SignatureAlgorithm { tbsCertificate.signature }
    var signatureValue: BitString
}

extension Certificate: ASN1Convertible {
    var asn1Tree: some ASN1Node {
        ASN1Seq {
            tbsCertificate
            algorithm
            signatureValue
        }
    }
}

extension Certificate {
    struct TBSCertificate {
        var version: Version
        var serialNo: UInt64
        var signature: SignatureAlgorithm
        var issuer: Name
        var validity: Validity
        var subject: Name
        var subjectPublicKeyInfo: SubjectPublicKeyInfo
    }
}

extension Certificate.TBSCertificate: ASN1Convertible {
    var asn1Tree: some ASN1Node {
        ASN1Seq {
            version
            serialNo
            signature
            issuer
            validity
            subject
            subjectPublicKeyInfo
        }
    }
}

extension Certificate {
    enum Version: Int, Hashable {
        case v3 = 2
    }
}

extension Certificate.Version: ASN1Convertible {
    var asn1Tree: some ASN1Node {
        ASN1Obj(tag: 0) {
            rawValue
        }
    }
}

extension Certificate {
    enum SignatureAlgorithm: Hashable {
        case ecdsaWithSHA256

        var oid: OID {
            switch self {
            case .ecdsaWithSHA256:
                return [1, 2, 840, 10045, 4, 3, 2]
            }
        }
    }

    enum PublicKeyAlgorithm: Hashable {
        case p256
    }
}

extension Certificate.SignatureAlgorithm: ASN1Convertible {
    var asn1Tree: some ASN1Node {
        ASN1Seq {
            oid
        }
    }
}

extension Certificate.PublicKeyAlgorithm: ASN1Convertible {
    var asn1Tree: some ASN1Node {
        let x962: OID = [1, 2, 840, 10045]
        let ecPublicKey = x962.adding(2, 1)

        return ASN1Seq {
            ecPublicKey

            switch self {
            case .p256:
                let p256v1 = x962.adding(3, 1, 7)
                p256v1
            }
        }
    }
}

extension Certificate {
    struct Name: Equatable {
        var commonName: String?
        var emailAddress: String?
    }
}

extension Certificate.Name: ASN1Convertible {
    var asn1Tree: some ASN1Node {
        ASN1Seq {
            if let commonName = commonName {
                ASN1Set {
                    ASN1Seq {
                        OID.commonName
                        commonName
                    }
                }
            }

            if let emailAddress = emailAddress {
                ASN1Set {
                    ASN1Seq {
                        OID.emailAddress
                        ASN1.IA5String(content: emailAddress)
                    }
                }
            }
        }
    }
}

extension Certificate {
    struct Validity: Equatable {
        var notBefore: Date
        var notAfter: Date?
    }
}

extension Certificate.Validity: ASN1Convertible {
    var asn1Tree: some ASN1Node {
        ASN1Seq {
            ASN1.Time.date(notBefore)
            if let notAfter = notAfter {
                ASN1.Time.date(notAfter)
            } else {
                ASN1.Time.distantFuture
            }
        }
    }
}

extension Certificate {
    enum SubjectPublicKeyInfo {
        case p256(P256.Signing.PublicKey)
    }
}

extension Certificate.SubjectPublicKeyInfo: ASN1Convertible {
    var asn1Tree: some ASN1Node {
        switch self {
        case .p256(let publicKey):
            return RawDER(data: publicKey.derRepresentation)
        }
    }
}
