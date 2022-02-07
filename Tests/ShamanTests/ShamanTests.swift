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
    
    func testMidState() throws {
        let tag = "BIP0340/nonce"
        var hasher = SHA256()
        let tagData = tag.data(using: .ascii)!
        hasher.update(data: tagData)
        let once = Data(hasher.finalize())
        let inputForTwice = Data(once + once)
        hasher.update(data: inputForTwice)
        let twice = Data(hasher.finalize())
        XCTAssertEqual(twice.hexString, "5301f1001a8be6253a3583927793565cef360de8bac2bdcbf37b195e699435a8")
//        XCTAssertEqual(twice.hexString, "46615b35f4bfbff79f8dc67183627ab3602171805735866121a29e5468b07b4c")
        
    }
    
    func testCacheMidState() throws {
        var hasher = SHA256()
//        try hasher.fixState(to: )
        let midstate = try Data(hex: "46615b35f4bfbff79f8dc67183627ab3602171805735866121a29e5468b07b4c")
        try midstate.withUnsafeBytes { midStatePointer in
            try hasher.fixState(to: midStatePointer)
        }
        XCTAssertEqual("5301f1001a8be6253a3583927793565cef360de8bac2bdcbf37b195e699435a8", Data(hasher.finalize()).hexString)
    }
}
