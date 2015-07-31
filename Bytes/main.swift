//
//  main.swift
//  Bytes
//
//  Created by Rasmus Kildevæld   on 29/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Foundation


func time (fn: () -> Void) -> Double {
    let start: clock_t, end: clock_t;
    let elapsed: Double;
    start = clock();
    
    fn()
    //Start code to time
    
    //End code to time
    
    end = clock();
    elapsed = Double(end - start) / Double(CLOCKS_PER_SEC);
    print("time \(elapsed)")
    return elapsed
}


extension Writable {
    
    public func write(readable: Readable, bufferSize: Int) -> Int {
        var len = 0, written = 0
        
        let buffer = UnsafeMutablePointer<UInt8>.alloc(bufferSize)
        
        repeat {
            
            len = readable.read(buffer, length: bufferSize)
            
            if len > 0 {
                self.write(buffer, length: len)
            }
            
            written += len
            
        } while len != 0
        
        buffer.destroy()
        buffer.dealloc(bufferSize)
        
        return written
    }
}

infix operator |> { associativity left precedence 160 }


func >>(lhs:Readable, rhs: Writable) -> Int {
    return rhs.write(lhs, bufferSize: 1024*1024)
}

func >>(lhs:String, rhs:Writable) -> Int {
    let file = ReadableFileStream(lhs)
    
    if file == nil {
        return -1
    }
    
    return file! >> rhs
}

func >>(lhs:Readable, rhs: String) -> Int {
    
    let file = WritableFileStream(rhs, append: true)
    
    if file == nil {
        return -1
    }
    
    return lhs >> file!
}

func >(lhs:Readable, rhs: String) -> Int {
    
    let file = WritableFileStream(rhs, append: false)
    
    if file == nil {
        return -1
    }
    
    return file!.write(lhs, bufferSize: 1024*1024)
}

func copyFile(source:String, target: String) {
    errno = 0
    let f = ReadableFileStream(source)
    if f == nil {
        print("Could not open file")
        exit(errno)
    }
    
    let file = f!
    
    file.bufferSize = 1024*1024 //1024*1024 * 100
    //file.bufferSize = 16
    //let data = file.read()
    
    let newFile = WritableFileStream(target)
    newFile?.bufferSize = 1024*1024 //1024*1024 * 100
    /*time {
    newFile?.write(file)
    }*/
    time {
        file >> newFile!
    }
    
    
    
}


let byt = Bytes(count: 10)
let bbbb = "Test mig lige engang, så er du sød".bytes
byt.write("Test mig lige engang, så er du sød\n")
byt.write(2002, to:36)
//print(byt.array,bbbb )
let byt2 = Bytes(count: 10)

let rstream = BytesReader(bytes: byt)
let wstream = BytesWriter(bytes: byt2)

//rstream >> wstream

"/Users/rasmus/test-stream.txt" >> wstream
BytesReader(bytes:byt2) > "/Users/rasmus/test.text"
//let b: String? = byt2.scan(0, to: 36)
let c = byt[36..<44].int
let bb = byt2.read(0, to:36)
let len = bb!.write("Alt det som ingen ser", to: 36)
let b = bb![0..<36 + len].string//byt2.scan(0, to: 36 + len)

print(b)
print(c)

//copyFile("/Users/rasmus/Desktop/dataloger.png", target: "/Users/rasmus/someting-new.png")
//let string: String? = data?.read()
//print(string)