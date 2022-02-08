//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation

public protocol CachedHasherState: Equatable & CustomStringConvertible {}

public protocol CacheableHasher {
    associatedtype CachedState: CachedHasherState
    mutating func updateAndCacheState(input: UnsafeRawBufferPointer, stateDescription: String?) -> CachedState
    mutating func restore(cachedState: inout CachedState)
}

// MARK: - CacheableHasher Convenience
// MARK: -
public extension CacheableHasher {
    
    mutating func updateAndCacheState(input: UnsafeRawBufferPointer) -> CachedState {
        updateAndCacheState(input: input, stateDescription: nil)
    }
    
    mutating func updateAndCacheState<D: DataProtocol>(
        data bytes: D,
        stateDescription: String? = nil
    ) -> CachedState {
        Data(bytes).withUnsafeBytes { dataPointer in
            updateAndCacheState(input: dataPointer, stateDescription: stateDescription)
        }
    }
}
