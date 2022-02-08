import Foundation

import protocol Crypto.HashFunction
import BridgeToC

// MARK: - Shaman256
// MARK: -
public struct Shaman256: CacheableHasher & HashFunction {
    
    internal let wrapper: Wrapper

    public init() {
        self.wrapper = Wrapper()
    }
}

// MARK: - HashFunction
// MARK: -
public extension Shaman256 {
    typealias Digest = ShamanDigest
    static var blockByteCount = 64
    static let byteCount = 32
    
    mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        wrapper.update(bufferPointer: bufferPointer)
    }

    /// Returns the digest from the data input in the hash function instance.
    ///
    /// - Returns: The digest of the inputted data
    func finalize() -> Digest {
        wrapper.finalize()
    }
    
}

// MARK: - CacheableHasher
// MARK: -
public extension Shaman256 {
    mutating func restore(cachedState: inout CachedState) {
        wrapper.restore(cachedState: &cachedState)
    }
    
    mutating func updateAndCacheState(input: UnsafeRawBufferPointer, stateDescription: String?) -> CachedState {
        wrapper.updateAndCacheState(input: input, stateDescription: stateDescription)
    }
}


// MARK: - Tag Testing
// MARK: -
internal extension Shaman256 {
    
    mutating func restore(
        state: Data,
        description: String? = nil
    ) throws {
        var cachedState = try Shaman256.CachedState.init(stateData: state, description: description)
        restore(cachedState: &cachedState)
    }
}
