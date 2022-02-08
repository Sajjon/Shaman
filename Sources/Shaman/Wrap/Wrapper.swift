//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation
import BridgeToC

// Optimally this would be a `struct` rather than a class. But in that case we
// would need to mark `finalize` as `mutating` since we re-initialize the
// `secp256k1_sha256` for reuse in finalize, which we want, because this allows
// us to reuse this Wrapper's `secp256k1_sha256` and thus we can reuse the
// instance of this class in `Shaman256`, which gives us the performance we want
// in the typical use case of PoW. i.e. we not only offers the ability to restore
// state, but even after finalization we can restore state.
internal final class Wrapper: CacheableHasher {
    internal var hasher: secp256k1_sha256

    /// Initializes the hash function instance.
    public init() {
        self.hasher = secp256k1_sha256()
        initHasher()
    }
}

internal extension Wrapper {
    
    typealias CachedState = Shaman256.CachedState
   
    
    @inlinable
    func initHasher() {
        secp256k1_sha256_initialize(&hasher)
    }
    
    @inlinable
    func update(bufferPointer: UnsafeRawBufferPointer) {
        secp256k1_sha256_write(&hasher, bufferPointer.baseAddress, bufferPointer.count)
    }
    
    @inlinable
    func updateAndCacheState(input: UnsafeRawBufferPointer, stateDescription: String?) -> CachedState {
        update(bufferPointer: input)
        return CachedState.init(cachedState: hasher, description: stateDescription)
    }
    
    @inlinable
    func restore(cachedState: inout CachedState) {
//        secp256k1_copy_hasher_state(&hasher, &cachedState.wrappedHasher)
        hasher = cachedState.wrappedHasher
    }
    
    /// Returns the digest from the data input in the hash function instance.
    ///
    /// - Returns: The digest of the inputted data
    @inlinable func finalize() -> Shaman256.Digest {
        defer { initHasher() } // reset state, make ready to be reused.
        var out = [UInt8](repeating: 0x00, count: Shaman256.Digest.byteCount)
        secp256k1_sha256_finalize(&hasher, &out)
        
        return out.withUnsafeBytes { source in
            guard let digest = Shaman256.Digest(bufferPointer: source) else {
                fatalError("Incorrect implementation, should always be able to create digest from hashers internal state.")
            }
            return digest
        }
        
        
    }
}
