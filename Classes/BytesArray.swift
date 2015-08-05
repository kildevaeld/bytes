//
//  BytesArray.swift
//  Bytes
//
//  Created by Rasmus Kildevæld   on 03/08/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin


public typealias Byte = UInt8

public protocol ByteArrayType {
    var count: Int { get }
    var array: [Byte] { get }
    func read(index: Int) -> Byte
    func read(index: Int, end:Int) -> [Byte]
    
}

public protocol MutableByteArrayType {
    func write(byte: Byte, index: Int)
    func write(bytes:UnsafePointer<Byte>, index: Int, length: Int) -> Int
}


extension MutableByteArrayType {
    public func write(bytes:BytesConvertible) -> Int {
        return self.write(bytes, index: 0)
    }
    public func write(bytes:ByteArrayType, index: Int) -> Int {
        return self.write(bytes.array, index: index, length: bytes.count)
    }
    
    public func write(bytes:BytesConvertible, index: Int) -> Int {
        let b = bytes.bytes
        return self.write(b, index: index, length: b.count)
    }
    
}




public class ByteArray : ByteArrayType, MutableByteArrayType {
    public typealias Generator = IndexingGenerator<ByteArray>
    public typealias SubSlice = ByteArraySlice
    public typealias Element = Byte
    public typealias Index = Int

    public var buffer: UnsafeMutablePointer<Byte>
    private var _len: Int
    
    public var count: Int {
        return self._len
    }
    
    convenience init() {
        self.init(count:0)
    }
    
    init(count: Int) {
        self.buffer = UnsafeMutablePointer<Byte>.alloc(count)
        self.buffer.initializeZero(count)
        self._len = count
    }
    
    convenience init(_ bytes: [Byte]) {
        var b = bytes
        self.init(&b, length: bytes.count)
    }
    
    init(_ bytes: UnsafePointer<Byte>, length:Int) {
        self.buffer = UnsafeMutablePointer<Byte>.alloc(length)
        bcopy(bytes, self.buffer, length)
        self._len = length
    }
    
    public func read(index: Int) -> Byte {
        return self.buffer[index]
    }
    
    public func read(index: Int, end:Int) -> [Byte] {
        let count = end - index
        var buffer = [Byte](count:count, repeatedValue: 0)
        self.read(&buffer, range: Range(start:index,end:end))
        return buffer
    }
    
    public func read(range:Range<Int>) -> ByteArraySlice?  {
        if range.endIndex > self.count { return nil }
        let slice = ByteArraySlice(self, range: range)
        return slice
    }
    
    public func read(buffer:UnsafeMutablePointer<Byte>, range: Range<Int>) -> Int {
        if range.endIndex > self.count { return -1 }
        let index = range.startIndex
        let len = range.startIndex + range.endIndex
        
        let buf = index == 0 ? self.buffer : self.buffer.advancedBy(index)
        
        bcopy(buf, buffer, len)

        
        return len
    }

    public func write(byte: Byte, index: Int) {
        self.buffer[index] = byte
    }
    
    public func write(bytes:UnsafePointer<Byte>, index: Int, length: Int) -> Int {
        let totalSize = index + length
        if totalSize > self.count {
            self.grow(totalSize - self.count)
        }
        
        let buf = index == 0 ? self.buffer : self.buffer.advancedBy(index)
        
        bcopy(bytes, buf, length)
        
        return length
    }
    
    func grow(length: Int) {
        let len = self.count + length
        let buffer = UnsafeMutablePointer<Byte>.alloc(len)
        
        bcopy(self.buffer, buffer, self.count)
        
        self.buffer.destroy()
        self.buffer.dealloc(self._len)
        
        self.buffer = buffer
        self._len = len
    }
    
    public var array : Array<Byte> {
        let len = self.count
        var a = [UInt8](count: len, repeatedValue: 0)
        bcopy(self.buffer, &a, len)
        return a
    }

    deinit {
        self.buffer.destroy()
        self.buffer.dealloc(self.count)
    }

}


extension ByteArray: CollectionType {
    
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

extension ByteArray: Sliceable {
    
    public subscript(range: Range<Int>) -> ByteArraySlice {
        get {
            return self.read(range)!
        }
        set (value) {
            var bytes = value.array
            self.write(&bytes, index: range.startIndex, length: range.count)
        }
    }
    
    /*public subscript(i: Int) -> String? {
        set (value) {
            if value == nil {
                return
            }
            
            self.write(value!, index: i)
        } get {
            self.read(Range(start:i, end: self.count))!.string
        }
    }*/
}
