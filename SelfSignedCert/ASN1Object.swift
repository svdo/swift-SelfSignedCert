//  Copyright © 2016 Stefan van den Oord. All rights reserved.

import Foundation

class ASN1Object : NSObject {
    let tag: UInt8
    let tagClass: UInt8
    let components: [NSObject]?
    let constructed: Bool
    let value: [UInt8]?
    
    convenience init(tag:UInt8, tagClass:UInt8, components:[NSObject]) {
        self.init(tag:tag, tagClass:tagClass, components:components, constructed:false, value:nil)
    }
    
    convenience init(tag:UInt8, tagClass:UInt8, constructed:Bool, value:[UInt8]) {
        self.init(tag:tag, tagClass:tagClass, components:nil, constructed:constructed, value:value)
    }
    
    private init(tag:UInt8, tagClass:UInt8, components:[NSObject]?, constructed:Bool, value:[UInt8]?) {
        self.tag = tag
        self.tagClass = tagClass
        self.constructed = constructed
        self.value = value
        self.components = components
    }
    
    override var description: String {
        if components != nil {
            return String(format:"\(type(of: self))[%hhu/%u/%u]%@", tagClass, constructed ? 1 : 0, tag, components!);
        }
        else {
            return String(format:"\(type(of: self))[%hhu/%u/%u, %u bytes]", tagClass, constructed ? 1 : 0, tag, value!.count);
        }

    }
}

