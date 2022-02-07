import XCTest
@testable import Shaman

final class ShamanTests: XCTestCase {
    
    func testSHA256() {
        
        @discardableResult
        func doTest(input: Data, expected: String) -> Data {
            // https://en.bitcoin.it/wiki/Test_Cases
            let digest = SHA256.hash(data: input)
            let hash = Data(digest)

            XCTAssertEqual(
                hash.hexString,
                expected
            )

            return hash
        }
        
        let once = doTest(input: "hello".data(using: .utf8)!, expected: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        doTest(input: once, expected: "9595c9df90075148eb06860365df33584b75bff782a510c6cd4883a419833d50")
        
        
    }
    
    func test_fixState_to() throws {
        var hasher = SHA256()
        try hasher.fixState(to: Data(hex: "46615b35f4bfbff79f8dc67183627ab3602171805735866121a29e5468b07b4c"))
        XCTAssertEqual(hashBIP340Tag(), Data(hasher.finalize()))
    }
    
    func test_update_cacheTo() throws {
        var hasher = SHA256()
        var cachedMidstate = Data(repeating: 0x00, count: 32)
        let once = Data(SHA256.hash(data: bip340Tag.data(using: .utf8)!))
        let data = Data(once + once)
        
        try data.withUnsafeBytes { dataPointer in
            try cachedMidstate.withUnsafeMutableBytes { targetPointer in
                try hasher.update(
                    bufferPointer: dataPointer,
                    cacheStateIn: targetPointer
                )
            }
        }
    
        XCTAssertEqual(cachedMidstate.hexString, "46615b35f4bfbff79f8dc67183627ab3602171805735866121a29e5468b07b4c")
        try hasher.fixState(to: cachedMidstate)
        XCTAssertEqual(hashBIP340Tag().hexString, Data(hasher.finalize()).hexString)
    }
    
    func test_assert_that_caching_state_does_not_break_things() throws {
        // https://www.di-mgt.com.au/sha_testvectors.html
        let expected = "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"
       
        var hasher = SHA256()
        var midstate = Data(repeating: 0x00, count: 32)
        var lastMidstate = Data(repeating: 0x00, count: 32)
        
        let input = String(repeating: "a", count: 1000).data(using: .utf8)!
        for _ in 0..<1000 {
            try input.withUnsafeBytes { dataPointer in
                try midstate.withUnsafeMutableBytes { targetPointer in
                    try hasher.update(
                        bufferPointer: dataPointer,
                        cacheStateIn: targetPointer
                    )
                }
            }
            XCTAssertNotEqual(midstate, lastMidstate)
            lastMidstate = midstate
        }
        
        XCTAssertEqual(Data(hasher.finalize()).hexString, expected)
        
    }
}

private let bip340Tag = "BIP0340/nonce"
private extension ShamanTests {
    
    
    func hashBIP340Tag() -> Data {
        nestedHash(tag: bip340Tag)
    }
    
    /// Computes: SHA( SHA(tag) || SHA(tag))
    func nestedHash(tag: String) -> Data {
        let hashed = Data(SHA256.hash(data: tag.data(using: .utf8)!))
        return Data(SHA256.hash(data: Data(hashed + hashed)))
    }
}
