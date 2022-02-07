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
    
    func testCacheMidState() throws {
        
        /// Computes: SHA( SHA(tag) || SHA(tag))
        func expected() -> Data {
            let tag = "BIP0340/nonce"
            let hashed = Data(SHA256.hash(data: tag.data(using: .utf8)!))
            return Data(SHA256.hash(data: Data(hashed + hashed)))
        }
        
        var hasher = SHA256()
        try hasher.fixState(to: Data(hex: "46615b35f4bfbff79f8dc67183627ab3602171805735866121a29e5468b07b4c"))
        XCTAssertEqual(expected(), Data(hasher.finalize()))
    }
}
