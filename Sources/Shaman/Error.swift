//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-02-08.
//

import Foundation

public enum Error: Swift.Error, Equatable {
    case incorrectSizeOfFixedMidstate(got: Int, butExpected: Int)
}
