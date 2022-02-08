//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation
import BridgeToC

func inspectInnerState(of hasher: secp256k1_sha256) -> Data {
    var state = hasher.s
    return Data(withUnsafeBytes(of: &state) { statePointer in
        [UInt8](statePointer).chunked(into: 4)
            .map ({ $0.reversed() })
            .reduce([UInt8](), +)
    })
    
}

func inspectStateOf(hasher: Shaman256) -> Data {
    inspectInnerState(of: hasher.wrapper.hasher)
}

func inspectStateOf(tag: Shaman256.Tag) -> Data {
    inspectInnerState(of: tag.cachedState)
}
