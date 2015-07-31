//
//  BytesSlice.swift
//  Bytes
//
//  Created by Rasmus Kildevæld   on 31/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin

struct SlicePosition {
    let index: Int
    var to: Int
}

public class BytesSlice: BytesType {
    let bytes: Bytes
    var position: SlicePosition
    public var count: Int {
        return self.position.to
    }
    init (_ bytes: Bytes, position: SlicePosition) {
        self.bytes = bytes
        self.position = position
    }
    
    public func read(index: Int) -> UInt8 {
        return self.bytes.read(index + self.position.index)
    }
    
    public func read(index: Int, to: Int) -> BytesSlice? {
        return self.bytes.read(index + self.position.index, to: to)
    }
    
    public func scan<T: BytesConvertible>(index: Int, to: Int) -> T? {
        let slice = self.read(index, to:to)
        if slice == nil {
            return nil
        }
        return T(slice!)
    }
    
    public func write(byte:UInt8, to: Int) -> Int {
        let diff = self.position.to - to
        
        let ret = self.bytes.write(byte, to: self.position.index + to)
        
        if ret != -1 && diff < 0 {
            self.position.to += to
        }
        return ret
    }
    
    public func write(bytes:BytesConvertible, to:Int? = nil) -> Int {
        return self.write(bytes.bytes, length:nil, to: to)
    }
    
    public func write(bytes: [UInt8], length: Int? = nil, to:Int? = nil) -> Int {
        let index = to == nil ? 0 : to!
        let count = length == nil ? bytes.count : length!
        
        let diff = self.position.to - count
        
        let ret = self.bytes.write(bytes, length: count, to: index)
        
        if ret != -1 && diff < 0 {
            self.position.to += index
        }
        return ret
    }
    
    
    
    public func write(bytes:UnsafePointer<UInt8>, length:Int, to:Int? = nil) -> Int {
        let index = to == nil ? 0 : to!
        
        let diff = self.position.to - length
        
        let ret = self.bytes.write(bytes, length: length, to: index)
        
        if ret != -1 && diff < 0 {
            self.position.to += index
        }
        return ret
    }
    
    
    public var array: [UInt8] {
        
        var array = [UInt8](count: self.position.to, repeatedValue: 0)
        
        let buf = self.bytes.buffer.advancedBy(self.position.index)
        bcopy(buf,&array,self.position.to)
        
        return array
        
        
    }
}

extension BytesSlice : CollectionType, Sliceable {
    public typealias Generator = IndexingGenerator<BytesSlice>
    public typealias Element = UInt8
    public typealias Index = Int
    public typealias SubSlice = BytesSlice
    
    public var startIndex: Index {
        return 0
    }
    
    public var endIndex: Index {
        return self.position.to
    }
    
    public subscript(i: Index) -> UInt8 {
        get {
            return self.read(i)
        } set (value) {
            self.bytes[i] = value
        }
    }
    
    public func generate() -> Generator  {
        return IndexingGenerator(self)
    }
    
    public subscript(i: Range<Index>) -> BytesSlice {
        return self.read(i.startIndex, to: i.endIndex)!
    }
}

