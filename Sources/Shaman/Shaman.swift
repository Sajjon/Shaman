import Foundation

import protocol Crypto.HashFunction
import BridgeToC

// MARK: - SHA256
// MARK: -
public struct SHA256: Crypto.HashFunction {
    
    internal let wrapper: Wrapper

    public init() {
        self.wrapper = Wrapper()
    }
}

// MARK: - HashFunction
// MARK: -
public extension SHA256 {
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

// MARK: - Tag
// MARK: -
public extension SHA256 {
    mutating func restore(tag: Tag) {
        wrapper.restore(tag: tag)
    }
    
    mutating func update(
        bufferPointer inputPointer: UnsafeRawBufferPointer,
        tag: String
    ) -> Tag {
        wrapper.update(
            bufferPointer: inputPointer,
            tag: tag
        )
    }
}

// MARK: - Tag Convenience
// MARK: -
public extension SHA256 {
    
    mutating func restore(
        state: Data,
        description: String? = nil
    ) throws {
        let tag = try Tag(stateData: state, description: description)
        restore(tag: tag)
    }
    
    mutating func update<D: DataProtocol>(
        data bytes: D,
        tag: String
    ) -> Tag {
        Data(bytes).withUnsafeBytes { dataPointer in
            update(bufferPointer: dataPointer, tag: tag)
        }
    }
}
