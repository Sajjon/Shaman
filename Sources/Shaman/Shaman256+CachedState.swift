//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation
import BridgeToC

public extension Shaman256 {
    struct CachedState: CachedHasherState {
        
        internal var wrappedHasher: secp256k1_sha256
        public let stateDescription: String?
        
        internal init(
            cachedState: secp256k1_sha256,
            description stateDescription: String?
        ) {
            self.wrappedHasher = cachedState
            self.stateDescription = stateDescription
        }
    }
}

// MARK: - CustomStringConvertible
// MARK: -
public extension Shaman256.CachedState {
    var description: String {
        let tag = stateDescription.map { "\($0) - " } ?? ""
        let state = "state: \(inspectInnerState(of: wrappedHasher))"
        return [tag, state].joined(separator: "")
    }
}

// MARK: - Equatable
// MARK: -
public extension Shaman256.CachedState {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedHasher == rhs.wrappedHasher
    }
}

// MARK: - Testing
// MARK: -
internal extension Shaman256.CachedState {
    init(stateData: Data, description: String? = nil) throws {
        guard stateData.count == 32 else {
            throw Error.incorrectSizeOfFixedMidstate(got: stateData.count, butExpected: 32)
        }
        var hasher = secp256k1_sha256()
        stateData.withUnsafeBytes { (dataPointer: UnsafeRawBufferPointer) -> Void in
            secp256k1_sha256_init_with_state(&hasher, dataPointer.baseAddress, stateData.count)
        }
        self.init(cachedState: hasher, description: description)
    }
}
