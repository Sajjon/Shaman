//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation

public protocol HashFunctionWithSink {
    mutating func finalize(to bufferPointer: UnsafeMutableRawBufferPointer)
}
