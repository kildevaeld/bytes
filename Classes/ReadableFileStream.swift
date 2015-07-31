//
//  File.swift
//  Bytes
//
//  Created by Rasmus Kildevæld   on 29/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin

typealias filefd = Int32

func errorToString (var errorcode: Int32? = nil) -> String {
    if errorcode == nil {
        errorcode = errno
    }
    return String.fromCString(strerror(errorcode!))!
}

public struct FileStates {
    public let size: Int64
    init(stats:stat) {
        self.size = stats.st_size
    }
}

public enum FileError : ErrorType, CustomStringConvertible {
    var asOption: Int32 {
        switch self {
        case .ENOENT: return Darwin.ENOENT
        case .Unknown(let code):
            return code
        }
    }
    
    case ENOENT
    case Unknown(Int32)
    public var description: String {
        return errorToString(self.asOption)
    }
    
    init(code:Int32) {
        switch code {
        case Darwin.ENOENT: self = .ENOENT
        default:
            self = .Unknown(code)
        }
    }
}

public enum FileWhence {
    var option: Int32 {
        switch self {
        case .Current: return SEEK_CUR
        case .End: return SEEK_END
        case .Start: return SEEK_SET
        }
    }
    case Current
    case End
    case Start
}

public protocol Readable {
    //var isEmpty: Bool { get }
    func read (buffer:UnsafeMutablePointer<UInt8>, length: Int) -> Int
}



public class FileStream {
    public let path: String
    
    var descriptor: UnsafeMutablePointer<FILE>?
    var _filesize: Int?
    
    public var isValid: Bool {
        return self.descriptor != nil
    }
    
    public var size : Int {
        guard let file = self.descriptor else { return 0 }
        var size = _filesize == nil ? 0 : _filesize!
        
        if _filesize == nil {
            let prev = ftell(file);
            fseek(file, 0, SEEK_END);
            size = ftell(file);
            fseek(file,prev,SEEK_SET); //go back to where we were
            _filesize = size
        }
        
        return size
    }
    
    init(path: String) {
        self.path = path
    }
    
    func open(mode: String ) throws {
        if self.descriptor != nil {
            // TODO: Error handeling
            return
        }
        
        var errcode: Int32 = 0
        errno = 0
        let file = path.withCString { (ptr) -> UnsafeMutablePointer<FILE>? in
            let file = Darwin.fopen(ptr, mode)
            errcode = errno
            //errno = 0
            if errcode == ENOENT {
                return nil
            }
            return file
        }
        
        if file == nil {
            throw FileError.Unknown(errcode)
        }
        
        self.descriptor = file
    }
    
    public func seek(offset: Int, whence:FileWhence) {
        guard let file = self.descriptor else { return }
        fseek(file, offset, whence.option)
    }
    
    public func close () {
        guard let file = self.descriptor else { return }
        Darwin.fclose(file)
        file.destroy()
        self.descriptor = nil
    }
    
    deinit {
        self.close()
    }
}

public final class ReadableFileStream : FileStream, Readable {
    
    public var bufferSize: Int = 1
    
    public var isEmpty : Bool {
        return self.tell == self.size
    }
    
    public func open(binary: Bool = true) throws {
        try super.open("r" + (binary ? "b" : ""))
    }
    
    
    public init?(_ path: String, binary: Bool = true) {
        super.init(path: path)
        do {
            try self.open(binary)
        } catch {
            return nil
        }
    
    }
    
    public func read (var length:Int) -> [UInt8]? {
        guard let file = self.descriptor else { return nil }
        length = length > self.size ? self.size : length
        var output = [UInt8](count: length, repeatedValue: 0)
        var bSize = self.bufferSize  > length ? length : self.bufferSize
        
        var len = 0, read = 0, index = 0
        var buf = [UInt8](count: bSize, repeatedValue: 0)
        repeat {
            len = fread(&buf, sizeof(UInt8), bSize, file)
            read += len
            
            if len == length {
                output = buf
            } else if len > 1 {
                
                for i in 0...len {
                    output[index + i] = buf[i]
                }
                //index += len
                
            } else {
                output[index] = buf[0]
            }
            
            let diff = length - read
            if diff < bSize && diff > 0 {
                bSize = diff
                buf = [UInt8](count: bSize, repeatedValue: 0)
            }
        
            index += len
        } while len != 0 && read < length
        return buf
    }
    
    public func read(buffer: UnsafeMutablePointer<UInt8>, length:Int) -> Int {
        guard let file = self.descriptor else { return -1 }
        return Darwin.fread(buffer, sizeof(UInt8), length, file)
    }
    
    
    public var tell: Int {
        return ftell(self.descriptor!)
    }
    
    /*public func read() -> Bytes? {
        return Bytes(buffer:self.read(self.size)!)
    }*/
    
    public subscript(index: Int) -> UInt8 {
        let prev = self.tell
        self.seek(index, whence: .Start)
        let result = self.read(1)!
        self.seek(prev, whence: .Start)
        
        return result[0]
    }
    
    
}

extension ReadableFileStream : SequenceType {
    public typealias Generator = AnyGenerator<UInt8>
    public func generate() -> Generator {
        self.seek(0, whence: .Start)
        return anyGenerator {
            if !self.isEmpty {
                let b = self.read(1)!
                return b[0]
            }
            return nil
        }
    }
}

