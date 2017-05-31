//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

class CertificateName : NSObject {
    private(set) var components: [ Set<NSMutableArray> ]
    
    var commonName: String {
        get { return string(for: OID.commonName) }
        set { setString(newValue, forOid:OID.commonName) }
    }
    var emailAddress: String {
        get { return string(for: OID.email) }
        set { setString(newValue, forOid:OID.email) }
    }
    
    override init() {
        components = []
        super.init()
    }
    
    func string(for oid:OID) -> String {
        guard let pair = pair(for: oid), let str = pair[1] as? String else {
            return ""
        }
        return str
    }
    
    func setString(_ string:String, forOid oid:OID) {
        if let pair = pair(for: oid) {
            pair[1] = string
        }
        else {
            components.append([[oid, string]])
        }
    }
    
    private func pair(for oid:OID) -> NSMutableArray? {
        let filtered = components.filter { set in
            guard let array = set.first, let filteredOid = array[0] as? OID else {
                return false
            }
            return filteredOid == oid
        }
        if filtered.count == 1 {
            return filtered[0].first
        }
        else {
            return nil
        }
    }
}
