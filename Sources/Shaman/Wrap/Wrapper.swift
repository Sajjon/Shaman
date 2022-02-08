//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation
import BridgeToC

internal final class Wrapper {
    internal var hasher: secp256k1_sha256

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
