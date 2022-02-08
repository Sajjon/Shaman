//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation

import protocol Crypto.Digest

public struct ShamanDigest: Crypto.Digest {
    let bytes: State
    
    init?(bufferPointer: UnsafeRawBufferPointer) {
        guard bufferPointer.count == Self.byteCount else {
            return nil
        }

        var bytes = (UInt64(0), UInt64(0), UInt64(0), UInt64(0))
        withUnsafeMutableBytes(of: &bytes) { targetPtr in
            targetPtr.copyMemory(from: bufferPointer)
        }
        self.bytes = bytes
    }
}

// MARK: - Digest
// MARK: -
public extension ShamanDigest {
    static let byteCount = 32
    
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try Swift.withUnsafeBytes(of: bytes) {
            let boundsCheckedPtr = UnsafeRawBufferPointer(
                start: $0.baseAddress,
                count: Self.byteCount
            )
            return try body(boundsCheckedPtr)
        }
    }
}

// MARK: - Equatable
// MARK: -
public extension ShamanDigest {
    static func == (lhs: Self, rhs: Self) -> Bool {
        safeCompare(lhs, rhs)
    }
    
    static func == <D: DataProtocol>(lhs: Self, rhs: D) -> Bool {
        if rhs.regions.count != 1 {
            let rhsContiguous = Data(rhs)
            return safeCompare(lhs, rhsContiguous)
        } else {
            return safeCompare(lhs, rhs.regions.first!)
        }
    }
}

// MARK: - Hashable
// MARK: -
public extension ShamanDigest {
    func hash(into hasher: inout Hasher) {
        withUnsafeBytes { hasher.combine(bytes: $0) }
    }
}

// MARK: - CustomStringConvertible
// MARK: -
public extension ShamanDigest {
    var description: String {
        "Shaman256 digest: \(toArray().hexString)"
    }
}

// MARK: - Private
// MARK: -
private extension ShamanDigest {
    
    func toArray() -> ArraySlice<UInt8> {
        var array = [UInt8]()
        array.appendByte(bytes.0)
        array.appendByte(bytes.1)
        array.appendByte(bytes.2)
        array.appendByte(bytes.3)
        return array.prefix(upTo: Self.byteCount)
    }

}

// MARK: - Internal
// MARK: -
internal extension ShamanDigest {
    typealias State = (UInt64, UInt64, UInt64, UInt64)
}

