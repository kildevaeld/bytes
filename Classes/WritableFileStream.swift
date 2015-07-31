//
//  WritableFileStream.swift
//  Bytes
//
//  Created by Rasmus Kildevæld   on 29/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin
import Dispatch

public protocol Writable {
    func write(bytes: UnsafeMutablePointer<UInt8>, length: Int) -> Int
}

public class WritableFileStream : FileStream, Writable {
    
    public var bufferSize: Int = 1024
    
    /*public func write(bytes: Bytes) {
        self.write(bytes, length: bytes.count)
    }
    
    public func write(bytes: Bytes, length: Int) -> Int {
        return self.write(bytes.buffer, length: length)
    }*/
    
    public func write(bytes: [UInt8], length: Int) -> Int {
        guard let file = self.descriptor else { return -1 }
        let slice = length == bytes.count ? bytes : [UInt8](bytes[0..<length])
        var bufSize = self.bufferSize
        var written = 0, len = 0
        
        repeat {
            let s: [UInt8]
            if length == written {
                break
            } else if length - written < bufSize {
                bufSize = 1
            }
            if length - written == 1 {
                s = [slice[written]]
            } else {
                s = [UInt8](slice[written..<(written + bufSize)]) // slice!.read(written, to: written + bufSize)
            }
            let buf = UnsafePointer<UInt8>(s)
            len = fwrite(buf, sizeof(UInt8), bufSize, file)
            
            written += len
            
        } while written <= length && len != 0
        
        return written
    }
    
    public func write(bytes:UnsafeMutablePointer<UInt8>, length:Int) -> Int {
        guard let file = self.descriptor else { return -1 }
        return Darwin.fwrite(bytes, sizeof(UInt8), length, file)
    }

    /*public func write(bytes:Readable) -> Int {
        guard let _ = self.descriptor else { return -1 }
        var written: Int = 0
        
        var len = 0, bufSize = self.bufferSize
        let buffer = UnsafeMutablePointer<UInt8>.alloc(bufSize)
        repeat {
            len = bytes.read(buffer, length: bufSize)
            if len > 0 {
                written += self.write(buffer, length: len)
            }
        } while len > 0
        
        buffer.destroy()
        buffer.dealloc(bufSize)
        
        return written
    }*/
    
    public func write<T: SequenceType where T.Generator.Element == UInt8>(bytes:T, length:Int) -> Int {
        guard let file = self.descriptor else { return -1 }
        var bufSize = self.bufferSize
        bufSize = bufSize > length ? length : bufSize
        var buf = [UInt8](count: bufSize, repeatedValue: 0)
        var i = 0, ii = 0, written = 0
        for item in bytes {
            
            if ii < bufSize && i != length {
                buf[ii++] = item
            }
            if bufSize == ii || i == length {
                if ii == bufSize {
                    written += fwrite(&buf, sizeof(UInt8), bufSize, file)
                }
                
                ii = 0
            }
            
            if i == length {
                break
            }
            
            i++
            
            let diff = length - written
            if diff < bufSize && diff > 0 {
                bufSize = diff
                buf = [UInt8](count: bufSize, repeatedValue: 0)
            }
         }
        
        return written
        
    }
    
    public init?(_ path: String, binary: Bool = true, append: Bool = false) {
        super.init(path: path)
        do {
            try self.open(binary, append: append)
        } catch {
            return nil
        }
        
    
    }
    
    public func open(binary: Bool = true, append: Bool = false) throws {
        let mode = (append ? "a" : "w") + (binary ? "b" : "")
        try super.open(mode)
    }
    
    public func flush () {
        guard let file = self.descriptor else { return }
        Darwin.fflush(file)
    }
    
    override public func close() {
        self.flush()
        super.close()
    }
}
