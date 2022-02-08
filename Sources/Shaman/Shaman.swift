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

func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
    withUnsafeBytes(of: value.bigEndian, Array.init)
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

private func inspectInnerState(of hasher: secp256k1_sha256) -> Data {
    var state = hasher.s
    return Data(withUnsafeBytes(of: &state) { statePointer in
        [UInt8](statePointer).chunked(into: 4)
            .map ({
                print("🔮 \($0.hexString)")
                return $0.reversed()
            })
            .reduce([UInt8](), +)
    })
    
}

func inspectStateOf(hasher: SHA256) -> Data {
    inspectInnerState(of: hasher.wrapper.hasher)
}
func inspectStateOf(tag: SHA256.Tag) -> Data {
    inspectInnerState(of: tag.cachedState)
}


internal func == (lhs: secp256k1_sha256, rhs: secp256k1_sha256) -> Bool {
    guard lhs.bytes == rhs.bytes else { return false }

    var lhsBuf = lhs.buf
    var rhsBuf = rhs.buf
    guard (withUnsafeBytes(of: &lhsBuf) { lhsBufPointer in
        withUnsafeBytes(of: &rhsBuf) { rhsBufPointer in
            guard lhsBufPointer.count == rhsBufPointer.count else {
                return false
            }
            for index in 0..<lhsBufPointer.count {
                if lhsBufPointer[index] != rhsBufPointer[index] {
                    return false
                }
            }
            return true
        }
    }) else {
        return false
    }

    var lhsState = lhs.s
    var rhsState = rhs.s
    guard (withUnsafeBytes(of: &lhsState) { lhsStatePointer in
        withUnsafeBytes(of: &rhsState) { rhsStatePointer in
            guard lhsStatePointer.count == rhsStatePointer.count else {
                return false
            }
            for index in 0..<lhsStatePointer.count {
                if lhsStatePointer[index] != rhsStatePointer[index] {
                    return false
                }
            }
            return true
        }
    }) else {
        return false
    }

    return true
}


public extension SHA256 {
    struct Tag: Equatable, CustomStringConvertible {
        internal var cachedState: secp256k1_sha256
        public let name: String
        
        internal init(cachedState: secp256k1_sha256, name: String) {
            self.cachedState = cachedState
            self.name = name
        }
        
        fileprivate init(stateData: Data, description: String? = nil) throws {
            guard stateData.count == 32 else {
                throw Error.incorrectSizeOfFixedMidstate(got: stateData.count, butExpected: 32)
            }
            var hasher = secp256k1_sha256()
            stateData.withUnsafeBytes { (dataPointer: UnsafeRawBufferPointer) -> Void in
                secp256k1_sha256_init_with_state(&hasher, dataPointer.baseAddress, stateData.count)
            }
            self.name = description ?? "fixed midstate"
            self.cachedState = hasher
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.cachedState == rhs.cachedState
        }
        
        public var description: String {
            "\(name) - state: \(inspectInnerState(of: cachedState))"
        }
    }
}

private final class Wrapper {
//    typealias StateKey = String
//    typealias State = ShamanDigest.State
//    private var cachedStates: [StateKey: State] = [:]
    fileprivate var hasher: secp256k1_sha256

    /// Initializes the hash function instance.
    public init() {
        self.hasher = secp256k1_sha256()
        initHasher()
    }
    
//    public init(fixedMidState: Data)
    
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
        tag: String
    ) -> SHA256.Tag {
        update(bufferPointer: inputPointer)
        return .init(cachedState: hasher, name: tag)
    }
    
    @inlinable
    func restore(tag: SHA256.Tag) {
        hasher = tag.cachedState
    }
    
    /// Returns the digest from the data input in the hash function instance.
    ///
    /// - Returns: The digest of the inputted data
    @inlinable func finalize() -> SHA256.Digest {
        defer { initHasher() } // reset state, make ready to be reused.
        var out = [UInt8](repeating: 0x00, count: SHA256.Digest.byteCount)
        secp256k1_sha256_finalize(&hasher, &out)
        
        return out.withUnsafeBytes { source in
            guard let digest = SHA256.Digest(bufferPointer: source) else {
                fatalError("Incorrect implementation, should always be able to create digest from hashers internal state.")
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
    
    fileprivate let wrapper: Wrapper

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
    
    mutating func restore(tag: Tag) {
        wrapper.restore(tag: tag)
    }
    
    mutating func restore(state: Data, description: String? = nil) throws {
        let tag = try Tag(stateData: state, description: description)
        restore(tag: tag)
    }
    
    mutating func update<D: DataProtocol>(
        data bytes: D,
        tag: String
    ) -> Tag {
        Data(bytes).withUnsafeBytes { dataPointer in
            update(bufferPointer: dataPointer, tag: tag)
        }
    }
    
    mutating func update(
        bufferPointer inputPointer: UnsafeRawBufferPointer,
        tag: String
    ) -> Tag {
        wrapper.update(bufferPointer: inputPointer, tag: tag)
    }
    
   
}

internal func safeCompare<LHS: ContiguousBytes, RHS: ContiguousBytes>(_ lhs: LHS, _ rhs: RHS) -> Bool {
    return openSSLSafeCompare(lhs, rhs)
}
