//    MIT License
//
//    Copyright (c) 2018 SharkChain Team
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation

extension String {
    
}

extension UInt64 {
    private func rawBytes() -> [UInt8] {
        let totalBytes = MemoryLayout<UInt64>.size
        var value = self
        return withUnsafePointer(to: &value) { valuePtr in
            return valuePtr.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { reboundPtr in
                return Array(UnsafeBufferPointer(start: reboundPtr, count: totalBytes))
            }
        }
    }
    func toHex() -> String {
        let byteArray = self.rawBytes().reversed()
        return byteArray.map{String(format: "%02X", $0)}.joined()
    }
}

extension UInt32 {
    private func rawBytes() -> [UInt8] {
        let totalBytes = MemoryLayout<UInt32>.size
        var value = self
        return withUnsafePointer(to: &value) { valuePtr in
            return valuePtr.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { reboundPtr in
                return Array(UnsafeBufferPointer(start: reboundPtr, count: totalBytes))
            }
        }
    }
    func toHex() -> String {
        let byteArray = self.rawBytes().reversed()
        return byteArray.map{String(format: "%02X", $0)}.joined()
    }
}

extension UInt8 {
    private func rawBytes() -> [UInt8] {
        let totalBytes = MemoryLayout<UInt8>.size
        var value = self
        return withUnsafePointer(to: &value) { valuePtr in
            return valuePtr.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { reboundPtr in
                return Array(UnsafeBufferPointer(start: reboundPtr, count: totalBytes))
            }
        }
    }
    func toHex() -> String {
        let byteArray = self.rawBytes().reversed()
        return byteArray.map{String(format: "%02X", $0)}.joined()
    }
}
