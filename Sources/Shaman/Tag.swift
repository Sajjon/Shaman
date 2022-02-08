//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation
import BridgeToC

public extension SHA256 {
    struct Tag: Equatable, CustomStringConvertible {
        
        internal var cachedState: secp256k1_sha256
        public let name: String
        
        internal init(
            cachedState: secp256k1_sha256,
            name: String
        ) {
            self.cachedState = cachedState
            self.name = name
        }
    }
}

// MARK: - Convenience Init
// MARK: - 
internal extension SHA256.Tag {
    init(stateData: Data, description: String? = nil) throws {
        guard stateData.count == 32 else {
            throw Error.incorrectSizeOfFixedMidstate(got: stateData.count, butExpected: 32)
        }
        var hasher = secp256k1_sha256()
        stateData.withUnsafeBytes { (dataPointer: UnsafeRawBufferPointer) -> Void in
            secp256k1_sha256_init_with_state(&hasher, dataPointer.baseAddress, stateData.count)
        }
        self.init(cachedState: hasher, name: description ?? "fixed midstate")
    }
}

// MARK: - CustomStringConvertible
// MARK: -
public extension SHA256.Tag {
    var description: String {
        "\(name) - state: \(inspectInnerState(of: cachedState))"
    }
}

// MARK: - Equatable
// MARK: -
public extension SHA256.Tag {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.cachedState == rhs.cachedState
    }
}
