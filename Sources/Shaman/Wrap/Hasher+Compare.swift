//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation
import BridgeToC

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
