//
//  extensions.swift
//  Bytes
//
//  Created by Rasmus Kildevæld   on 31/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin

public protocol BytesConvertible {
    var bytes: [UInt8] { get }
    init(_ bytes: [UInt8])
}

extension BytesConvertible {
    public init(_ bytes: ArraySlice<UInt8>) {
        self.init([UInt8](bytes))
    }
    
    public init(_ bytes: ByteArraySlice) {
        self.init(bytes.array)
    }
    
    public init(_ bytes: ByteArray) {
        self.init(bytes.array)
    }
}



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

extension ByteArrayType {
    public var string: String {
        
        return String(self.read(0, end: self.count))
    }
    
    public var int: Int {
        return Int(self.read(0, end: 8))
    }
    
    public var int64: Int64 {
        return Int64(self.read(0, end: 8))
    }
    
    public var int32: Int32 {
        return Int32(self.read(0, end: 4))
    }
    
    public var int16: Int16 {
        return Int16(self.read(0, end: 2))
    }
    
    public var int8: Int8 {
        return Int8(self.read(0, end: 1))
    }
    
    public var uint: UInt {
        return UInt(self.read(0, end: 8))
    }
    
    public var uint64: UInt64 {
        return UInt64(self.read(0, end: 8))
    }
    
    public var uint32: UInt32 {
        return UInt32(self.read(0, end: 4))
    }
    
    public var uint16: UInt16 {
        return UInt16(self.read(0, end: 2))
    }
    
    public var uint8: UInt8 {
        return UInt8(self.read(0, end: 1))
    }
    
    public func toString(from:Int?, to:Int) -> String {
        let index = from == nil ? 0 : from!
        let r = self.read(index, end:to)
        return String(r)
    }
}


