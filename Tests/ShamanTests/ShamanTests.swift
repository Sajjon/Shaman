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
        try hasher.restore(state: Data(hex: "46615b35f4bfbff79f8dc67183627ab3602171805735866121a29e5468b07b4c"))
        XCTAssertEqual(hashBIP340Tag(), Data(hasher.finalize()))
    }
    
    func test_update_cacheTo() {
        var hasher = SHA256()
        
        let half = Data(SHA256.hash(data: "BIP0340/nonce".data(using: .utf8)!))
        
        let tag = hasher.update(
            data: Data(half + half),
            tag: "some description"
        )
        
        XCTAssertEqual(inspectStateOf(tag: tag).hexString, inspectStateOf(hasher: hasher).hexString)
        let expectedMidstate = "46615b35f4bfbff79f8dc67183627ab3602171805735866121a29e5468b07b4c"
        XCTAssertEqual(inspectStateOf(tag: tag).hexString, expectedMidstate)
        
        let nonSenseInput = "non-sense data that must be 64 chars or longer, the purpose of which is to change the internal state of hasher"
        XCTAssertGreaterThanOrEqual(nonSenseInput.count, 64) // must be GEQ than 64 because the hasher has an internal buffer with size 64.
        hasher.update(data: nonSenseInput.data(using: .utf8)!)
        XCTAssertNotEqual(inspectStateOf(hasher: hasher).hexString, expectedMidstate)
        
        // Restore
        hasher.restore(tag: tag)
        XCTAssertEqual(inspectStateOf(tag: tag).hexString, expectedMidstate)
        
        XCTAssertEqual(hashBIP340Tag().hexString, Data(hasher.finalize()).hexString)
    }
    
    func test_assert_that_caching_state_does_not_break_things() {
        // https://www.di-mgt.com.au/sha_testvectors.html
        let expected = "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"
       
        var hasher = SHA256()
        var lastTag: SHA256.Tag!
        
        let input = String(repeating: "a", count: 1000).data(using: .utf8)!
        for _ in 0..<1000 {
            let tag = hasher.update(data: input, tag: "irrelevant tag")
            XCTAssertNotEqual(tag, lastTag)
            lastTag = tag
        }
        
        XCTAssertEqual(Data(hasher.finalize()).hexString, expected)
        
    }
    
    func test_assert_cache_state_various_padding() throws {
        // https://www.di-mgt.com.au/sha_testvectors.html
        let expected = "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"
        let length = 1_000_000
        
        for bytesLeft in 1..<100 {
            var referenceHasher = SHA256()
            var hasherUnderTest = SHA256()
            
            let initialInput = String(repeating: "a", count: length - bytesLeft).data(using: .utf8)!
            let midStateTag = referenceHasher.update(data: initialInput, tag: "initial input")
            let remainingInput = String(repeating: "a", count: bytesLeft).data(using: .utf8)!
            
            XCTAssertEqual(initialInput.count + remainingInput.count, length)
            
            hasherUnderTest.restore(tag: midStateTag)
            hasherUnderTest.update(data: remainingInput)
            XCTAssertEqual(Data(hasherUnderTest.finalize()).hexString, expected)
            referenceHasher.update(data: remainingInput)
            XCTAssertEqual(Data(referenceHasher.finalize()).hexString, expected)
        }
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
