//
//  extensions.swift
//  Bytes
//
//  Created by Rasmus Kildevæld   on 31/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin


extension String : BytesConvertible {
    public var bytes: [UInt8] {
        let buf = [UInt8](self.utf8)
        return buf
    }
    
    public init(_ bytes: [UInt8]) {
        let m = bytes.map { Utils.signed($0) }
        let str = String.fromCString(m)
        
        self = ""
        
        if str != nil {
            self = str!
        }
        
    }
}

extension Int8 : BytesConvertible {
    public var bytes: [UInt8] {
        let b = Utils.unsigned(self)
        return [b]
    }
    
    public init(_ bytes: [UInt8]) {
        self = Utils.signed(bytes[0])
    }
}

extension UInt8 : BytesConvertible {
    public var bytes: [UInt8] {
        return [self]
    }
    
    public init(_ bytes: [UInt8]) {
        let b = bytes[0]
        self = b
    }
}


extension Int16 : BytesConvertible {
    public var bytes: [UInt8] {
        let b = Utils.bytes(Utils.unsigned(self))
        return b
    }
    
    public init(_ bytes: [UInt8]) {
        self = Utils.signed(Utils.concatenateBytes(bytes[0], right: bytes[1]))
    }
}

extension UInt16 : BytesConvertible {
    public var bytes: [UInt8] {
        let b = Utils.bytes(self)
        return b
    }
    
    public init(_ bytes: [UInt8]) {
        self = Utils.concatenateBytes(bytes[0], right: bytes[1])
    }
    
}

extension Int32 : BytesConvertible {
    public var bytes: [UInt8] {
        let b = Utils.bytes(Utils.unsigned(self))
        return b
    }
    
    public init(_ bytes: [UInt8]) {
        let b = bytes
        self = Utils.signed(Utils.concatenateBytes(b[0], b1: b[1], b2: b[2], b3: b[3]))
    }
}

extension UInt32 : BytesConvertible {
    public var bytes: [UInt8] {
        let b = Utils.bytes(self)
        return b
    }
    
    public init(_ bytes: [UInt8]) {
        let b = bytes
        self = Utils.concatenateBytes(b[0], b1: b[1], b2: b[2], b3: b[3])
    }
}

extension Int64 : BytesConvertible {
    public var bytes: [UInt8] {
        let b = Utils.bytes(Utils.unsigned(self))
        return b
    }
    
    public init(_ bytes: [UInt8]) {
        let b = bytes
        self = Utils.signed(Utils.concatenateBytes(b[0], b1: b[1], b2: b[2], b3: b[3], b4: b[4], b5: b[5], b6: b[6], b7: b[7]))
    }
}

extension UInt64 : BytesConvertible {
    public var bytes: [UInt8] {
        let b = Utils.bytes(self)
        return b
    }
    
    public init(_ bytes: [UInt8]) {
        let b = bytes
        self = Utils.concatenateBytes(b[0], b1: b[1], b2: b[2], b3: b[3], b4: b[4], b5: b[5], b6: b[6], b7: b[7])
    }
}

extension Int : BytesConvertible {
    public var bytes: [UInt8] {
        let b = Utils.bytes(Utils.unsigned(Int64(self)))
        return b
    }
    
    public init(_ bytes: [UInt8]) {
        let b = bytes
        self = Int(Utils.signed(Utils.concatenateBytes(b[0], b1: b[1], b2: b[2], b3: b[3], b4: b[4], b5: b[5], b6: b[6], b7: b[7])))
    }
}

extension UInt : BytesConvertible {
    public var bytes: [UInt8] {
        let b = Utils.bytes(UInt64(self))
        return b
    }
    
    public init(_ bytes: [UInt8]) {
        let b = bytes
        self = UInt(Utils.concatenateBytes(b[0], b1: b[1], b2: b[2], b3: b[3], b4: b[4], b5: b[5], b6: b[6], b7: b[7]))
    }
}
