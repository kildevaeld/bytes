//
//  ByteArraySlice.swift
//  Bytes
//
//  Created by Rasmus Kildevæld   on 03/08/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin


public class ByteArraySlice : ByteArrayType, MutableByteArrayType {
    public typealias Generator = IndexingGenerator<ByteArraySlice>
    public typealias SubSlice = ByteArraySlice
    public typealias Element = Byte
    public typealias Index = Int
    
    var range: Range<Int>
    var bytes: ByteArray
    public var count: Int {
        return self.range.endIndex - self.range.startIndex
    }
    
    public init(_ bytes:ByteArray, range: Range<Int>) {
        self.range = range
        self.bytes = bytes
    }
    
    public func read(index: Int) -> Byte {
        return self.bytes[index]
    }
    
    public func read(index: Int, end: Int) -> [Byte] {
        return self.bytes.read(index + self.range.startIndex, end: self.range.startIndex + end)
    }

    public func write(byte: Byte, index: Int) {
        self.bytes[index] = byte
    }
    
    public func write(bytes:UnsafePointer<Byte>, index: Int, length: Int) -> Int {
        /*let totalSize = index + length
        if totalSize > self.count {
            self.grow(totalSize - self.count)
        }
        
        let buf = index == 0 ? self.buffer : self.buffer.advancedBy(index)
        
        bcopy(bytes, buf, length)
        
        self._len = totalSize
        
        return length*/
        return self.bytes.write(bytes, index: 0, length: 1)
    }
    
    
    public func read(range:Range<Int>) -> ByteArraySlice?  {
        return self.bytes.read(range)
    }
    
    public var array: [UInt8] {
        var array = [UInt8](count: self.count, repeatedValue: 0)
        
        self.bytes.read(&array, range: self.range)
        
        return array
    }
    
}

extension ByteArray {
    convenience init(_ bytes:BytesConvertible) {
        var b = bytes.bytes
        self.init(&b, length:b.count)
    }
}

extension ByteArraySlice {
    convenience init(_ bytes: BytesConvertible) {
        let byt = bytes.bytes
        let b = ByteArray(bytes.bytes)
        self.init(b, range: Range(start: 0, end:byt.count))
    }
}

extension ByteArraySlice : CollectionType {
    public var startIndex: Index {
        return 0
    }
    
    public var endIndex: Index {
        return self.count
    }
    
    public subscript(i: Index) -> Element {
        get {
            return self.read(i)
        } set (value) {
            self.write(value, index: i)
        }
    }
    
    public func generate() -> Generator  {
        return IndexingGenerator(self)
    }
}

extension ByteArraySlice : Sliceable {
    public subscript(range: Range<Int>) -> SubSlice {
        get {
            return self.read(range)!
        }
        set (value) {
            var val = value.array
            self.write(&val, index: range.startIndex, length: range.count)
        }
    }
    
}

