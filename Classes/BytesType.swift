//
//  BytesType.swift
//  Bytes
//
//  Created by Rasmus Kildevæld   on 03/08/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin

public protocol ReadableBytesType {
    var count: Int { get }
    //func read(index: Int, to:Int) -> BytesSlice?
    func read(index: Int) -> UInt8
    func read(buffer: UnsafeMutablePointer<UInt8>, index:Int,  to: Int) -> Int
}

public protocol WritableBytesType {
    func write(byte:UInt8, to: Int) -> Int
    func write(bytes:UnsafePointer<UInt8>, length:Int, to:Int) -> Int
}

public protocol BytesType : WritableBytesType, ReadableBytesType {
    
}


extension WritableBytesType {
    public func write(bytes:BytesConvertible, to:Int? = nil) -> Int {
        let b = bytes.bytes
        let index = to == nil ? 0 : to!
        return self.write(b, length:b.count, to: index)
        
    }
    
    

}

extension ReadableBytesType {
    public var array: [UInt8] {
        
        var array = [UInt8](count: self.count, repeatedValue: 0)
        self.read(&array, index: 0, to: self.count)
        return array
        
        
    }
}