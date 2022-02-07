import Foundation

import protocol Crypto.Digest
import protocol Crypto.HashFunction
import struct Crypto.SHA256Digest

import BridgeToC


protocol DigestPrivate: Digest {
    init?(bufferPointer: UnsafeRawBufferPointer)
}

extension DigestPrivate {
    @inlinable
    init?(bytes: [UInt8]) {
        let some = bytes.withUnsafeBytes { bufferPointer in
            return Self(bufferPointer: bufferPointer)
        }

        if some != nil {
            self = some!
        } else {
            return nil
        }
    }
}

public enum Error: Swift.Error, Equatable {
    case incorrectSizeOfFixedMidstate(got: Int, butExpected: Int)
}

private final class Wrapper {
//    typealias StateKey = String
//    typealias State = ShamanDigest.State
//    private var cachedStates: [StateKey: State] = [:]
    private var hasher: secp256k1_sha256

    /// Initializes the hash function instance.
    public init() {
        self.hasher = secp256k1_sha256()
        initHasher()
    }
    
    @inlinable
    func initHasher() {
        secp256k1_sha256_initialize(&hasher)
    }
    
    @inlinable
    func update(bufferPointer: UnsafeRawBufferPointer) {
        secp256k1_sha256_write(&hasher, bufferPointer.baseAddress, bufferPointer.count)
    }
    
    @inlinable
    func update(
        bufferPointer inputPointer: UnsafeRawBufferPointer,
        cacheStateIn pointerToCache: UnsafeMutableRawBufferPointer
    ) throws {
        print("🔮Wrapper🔮 update:bufferPointer:cacheStateIn => call `secp256k1_sha256_write_cache_state`")
        guard pointerToCache.count == SHA256.Digest.byteCount else {
            throw Error.incorrectSizeOfFixedMidstate(got: pointerToCache.count, butExpected: SHA256.Digest.byteCount)
        }
        secp256k1_sha256_write_cache_state(&hasher, inputPointer.baseAddress, inputPointer.count, pointerToCache.baseAddress)
    }
    
    @inlinable
    func fixState(to bufferPointer: UnsafeRawBufferPointer) throws {
        guard bufferPointer.count == SHA256.Digest.byteCount else {
            throw Error.incorrectSizeOfFixedMidstate(got: bufferPointer.count, butExpected: SHA256.Digest.byteCount)
        }
        print("fixState to 🔮")
        secp256k1_sha256_init_with_state(&hasher, bufferPointer.baseAddress, bufferPointer.count)
    }
    
    /// Returns the digest from the data input in the hash function instance.
    ///
    /// - Returns: The digest of the inputted data
    @inlinable func finalize() -> SHA256.Digest {
        defer { initHasher() } // reset state, make ready to be reused.
//        var out = Data(repeating: 0x00, count: SHA256.Digest.byteCount)
        var out = [UInt8](repeating: 0x00, count: SHA256.Digest.byteCount)
        secp256k1_sha256_finalize(&hasher, &out)
        
        return out.withUnsafeBytes { source in
            guard let digest = SHA256.Digest(bufferPointer: source) else {
                fatalError("Incorrect implementation")
            }
            return digest
        }
        
        
    }
}

public struct ShamanDigest: Crypto.Digest, DigestPrivate {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return safeCompare(lhs, rhs)
    }
    
    public static func == <D: DataProtocol>(lhs: Self, rhs: D) -> Bool {
        if rhs.regions.count != 1 {
            let rhsContiguous = Data(rhs)
            return safeCompare(lhs, rhsContiguous)
        } else {
            return safeCompare(lhs, rhs.regions.first!)
        }
    }

    
    public static var byteCount: Int = 32
    internal typealias State = (UInt64, UInt64, UInt64, UInt64)
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
    
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        return try Swift.withUnsafeBytes(of: bytes) {
            let boundsCheckedPtr = UnsafeRawBufferPointer(start: $0.baseAddress,
                                                          count: Self.byteCount)
            return try body(boundsCheckedPtr)
        }
    }

    private func toArray() -> ArraySlice<UInt8> {
        var array = [UInt8]()
        array.appendByte(bytes.0)
        array.appendByte(bytes.1)
        array.appendByte(bytes.2)
        array.appendByte(bytes.3)
        return array.prefix(upTo: SHA256Digest.byteCount)

    }
    
    public var description: String {
        return "\("SHA256") digest: \(toArray().hexString)"
    }
    
    public func hash(into hasher: inout Hasher) {
        self.withUnsafeBytes { hasher.combine(bytes: $0) }
    }
}

public struct SHA256: Crypto.HashFunction {
    
    private let wrapper: Wrapper

    public init() {
        self.wrapper = Wrapper()
    }
    
    

}

public extension SHA256 {
    typealias Digest = ShamanDigest
    static var blockByteCount = 64
    static let byteCount = 32
}

public extension SHA256 {
    
    mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        wrapper.update(bufferPointer: bufferPointer)
    }

    /// Returns the digest from the data input in the hash function instance.
    ///
    /// - Returns: The digest of the inputted data
    func finalize() -> Digest {
        wrapper.finalize()
    }
    
    mutating func fixState(to bufferPointer: UnsafeRawBufferPointer) throws {
        print("fixState to 🔮🔮")
        try wrapper.fixState(to: bufferPointer)
    }
    
    
    mutating func update(
        bufferPointer inputPointer: UnsafeRawBufferPointer,
        cacheStateIn pointerToCache: UnsafeMutableRawBufferPointer
    ) throws {
        print("🔮SHA256🔮 update:bufferPointer:cacheStateIn => call wrapper")
        try wrapper.update(bufferPointer: inputPointer, cacheStateIn: pointerToCache)
    }
    
//    @inlinable
//    mutating func fixState<D: DataProtocol>(to fixedMidState: D) throws {
//        print("fixState to 🔮🔮🔮🔮")
//        try fixedMidState.withContiguousStorageIfAvailable { body in
//            try body.withUnsafeBytes { source in
//                try self.fixState(to: source)
//            }
//        }
//    }
    
    @inlinable
    mutating func update<D: DataProtocol>(data: D, cacheStateIn pointerToCache: UnsafeMutableRawBufferPointer) throws {
        print("🔮SHA256🔮 update<D: DataProtocol>:data:pointerToCache => call self")
        try data.withContiguousStorageIfAvailable { dataBody in
            try dataBody.withUnsafeBytes { dataPointer in
                try self.update(bufferPointer: dataPointer, cacheStateIn: pointerToCache)
            }
        }
    }
}

internal func safeCompare<LHS: ContiguousBytes, RHS: ContiguousBytes>(_ lhs: LHS, _ rhs: RHS) -> Bool {
    return openSSLSafeCompare(lhs, rhs)
}
