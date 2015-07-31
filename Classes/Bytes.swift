//
//  Bytes.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 29/07/15.
//
//

import Darwin

extension UnsafeMutablePointer {
    ///Writes value to the pointer, optionally
    ///repeating repeatCount times.
    ///All use of this function is unsafe and
    ///should be reviewed thoroughly
    func write(value:UInt8, repeatCount:Int = 1) {
        self.write(value, startOffset: 0, repeatCount: repeatCount)
    }
    
    ///Writes value to the pointer, optionally
    ///starting at the given offset and repeating for repeatCount.
    ///All use of this function is unsafe and should be reviewed thoroughly
    func write(value:UInt8, startOffset:Int = 0, repeatCount:Int = 1) {
        memset(UnsafeMutablePointer<()>(self + startOffset),
            Int32(value), repeatCount)
        
    }
    
    func initializeZero(num:Int) {
        self.write(0, startOffset:0, repeatCount:Int(num))
    }
}

public protocol BytesConvertible {
    var bytes: [UInt8] { get }
    init(_ bytes: [UInt8])
}

extension BytesConvertible {
    public init(_ bytes: ArraySlice<UInt8>) {
        self.init([UInt8](bytes))
    }
    
    public init(_ bytes: BytesSlice) {
        self.init(bytes.array)
    }
}

public protocol BytesType  {
    var count: Int { get }
    func read(index: Int, to:Int) -> BytesSlice?
    func read(index: Int) -> UInt8
}

extension BytesType {
    public var string: String {
        return String(self.read(0, to: self.count)!)
    }
    
    public var int: Int {
        return Int(self.read(0, to: 8)!)
    }
    
    public func toString(from:Int?, to:Int) -> String {
        let index = from == nil ? 0 : from!
        let r = self.read(index, to: to)
        return String(r)
    }
}

public class Bytes : BytesType {
    public var buffer: UnsafeMutablePointer<UInt8>
    
    private var _len: Int
    public var count: Int {
        return self._len
    }
    
    init(count: Int) {
        self.buffer = UnsafeMutablePointer<UInt8>.alloc(count)
        self.buffer.initializeZero(count)
    
        self._len = count
    }
    
    init(var bytes:[UInt8]) {
        self.buffer = UnsafeMutablePointer<UInt8>.alloc(bytes.count)
        bcopy(&bytes, self.buffer, bytes.count)
        self._len = bytes.count
    }
    
    init(bytes:Bytes, copy: Bool = true) {
        if copy == true {
            self.buffer = UnsafeMutablePointer<UInt8>.alloc(bytes.count)
            bcopy(bytes.buffer, self.buffer, bytes.count)
        } else {
            self.buffer = bytes.buffer
        }
        
        self._len = bytes.count
    }
    
    convenience init(bytes:BytesSlice, copy: Bool = true) {
        self.init(bytes:bytes.bytes, copy: copy)
    }
    
    public func read(index: Int) -> UInt8 {
        return self.buffer[index]
    }
    
    public func read(index: Int, to: Int) -> BytesSlice? {
        if to > self.count { return nil }

        let position = SlicePosition(index: index, to: to)
        
        return BytesSlice(self, position: position)
    }
    
    public func scan<T: BytesConvertible>(index: Int, to: Int) -> T? {
        let slice = self.read(index, to:to)
        if slice == nil {
            return nil
        }
        return T(slice!)
    }
    
    public func write(byte:UInt8, to: Int) -> Int {
        if to >= self._len { return -1 }
        self.buffer[to] = byte
        return 0
    }
    
    public func write(bytes:BytesConvertible, to:Int? = nil) -> Int {
        return self.write(bytes.bytes, length:nil, to: to)
    }
    
    public func write(bytes: [UInt8], length: Int? = nil, to:Int? = nil) -> Int {
        let index = to == nil ? 0 : to!
        var size = length == nil ? bytes.count : length!
        size = size > bytes.count ? bytes.count : size
        
        let totalSize = index + size
        
        if totalSize > self.count {
            self.grow(totalSize)
        }
        var b : [UInt8]
        if size < self.count {
           b = [UInt8](bytes[0..<size])
        } else {
            b = bytes
        }
        
        let buf: UnsafeMutablePointer<UInt8>
        if index == 0 {
            buf = self.buffer
        } else {
            buf = self.buffer.advancedBy(index)
        }
        
        bcopy(&b, buf, size)
        
        return size
    }
    
    
    
    public func write(bytes:UnsafePointer<UInt8>, length:Int, to:Int? = nil) -> Int {
        let index = to == nil ? 0 : to!
        
        let totalLength = length + index
        
        if totalLength > self.count {
            self.grow(totalLength)
        }
        let buf: UnsafeMutablePointer<UInt8>
        
        if index == 0 {
            buf = self.buffer
        } else {
            buf = self.buffer.advancedBy(index)
        }
        
        bcopy(bytes, buf, length)
        
        return length
    }
    
    deinit {
        self.buffer.destroy()
        self.buffer.dealloc(self._len)
    }
    
    public var array: [UInt8] {
        
        var array = [UInt8](count: self.count, repeatedValue: 0)
        
        bcopy(self.buffer,&array,self.count)
        
        return array
    }
    
    public func grow(count: Int) {
        let len = self.count + count
        
        let newBuf = UnsafeMutablePointer<UInt8>.alloc(len)
        newBuf.moveInitializeFrom(self.buffer, count: self.count)
        
        self.buffer.destroy()
        self.buffer.dealloc(self.count)
        
        self.buffer = newBuf
        self._len = len
        
    }
    
    public func skrink(count:Int) {
        let len = self.count - count
        if len == 0 { return }
        
        let newBuf = UnsafeMutablePointer<UInt8>.alloc(len)
        newBuf.moveInitializeFrom(self.buffer, count: len)
        
        self.buffer.destroy()
        self.buffer.dealloc(self.count)
        
        self.buffer = newBuf
        self._len = len
    }
}

extension Bytes : CollectionType, Sliceable {
    public typealias Generator = IndexingGenerator<Bytes>
    public typealias Element = UInt8
    public typealias Index = Int
    public typealias SubSlice = BytesSlice
    
    public var startIndex: Index {
        return 0
    }
    
    public var endIndex: Index {
        return self.count
    }
    
    public subscript(i: Index) -> UInt8 {
        get {
            return self.read(i)
        } set (value) {
            self[i] = value
        }
    }
    
    public func generate() -> Generator  {
        return IndexingGenerator(self)
    }
    
    public subscript(i: Range<Index>) -> BytesSlice {
        return self.read(i.startIndex, to: i.endIndex)!
    }
}



public class BytesReader : Readable {
    let bytes: Bytes
    var index = 0
    public func read(buffer: UnsafeMutablePointer<UInt8>, length: Int) -> Int {
        if index >= self.bytes.count { return 0 }
        
        var len = index + length
        let diff = self.bytes.count - index
        if len > diff {
            len = diff
        }
        let b : UnsafeMutablePointer<UInt8>
        if index == 0 {
            b = self.bytes.buffer
        } else {
            b = self.bytes.buffer.advancedBy(index)
            
        }
        
        bcopy(b, buffer, len)
        index += len
        
        return len
    }
    
    init (bytes: Bytes) {
        self.bytes = bytes
    }
    
}

public class BytesWriter : Writable {
    let bytes: Bytes
    var index: Int = 0
    var bufferSize: Int = 1
    init (bytes: Bytes) {
        self.bytes = bytes
    }
    
    public func write(bytes: UnsafeMutablePointer<UInt8>, length: Int) -> Int {
        index += self.bytes.write(bytes, length: length, to: index)
        return length
    }
    
}

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




