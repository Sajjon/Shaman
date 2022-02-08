import XCTest
@testable import Shaman

final class ShamanTests: XCTestCase {
    
    func testSHA256() {
        
        @discardableResult
        func doTest(input: Data, expected: String) -> Data {
            // https://en.bitcoin.it/wiki/Test_Cases
            let digest = Shaman256.hash(data: input)
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
    
    func testRestoreToKnownPrecomputedState() throws {
        var hasher = Shaman256()
        try hasher.restore(state: Data(hex: bip340TagPrecomputedState))
        XCTAssertEqual(hashBIP340Tag(), Data(hasher.finalize()))
    }
    
    func testAssertContentsOfCachedStateByInspectingIt() {
        var hasher = Shaman256()
        
        let half = Data(Shaman256.hash(data: bip340Tag.data(using: .utf8)!))
        
        let stateDescription = "some important description we wanna assert against later"
        
        var cachedState = hasher.updateAndCacheState(
            data: Data(half + half),
            stateDescription: stateDescription
        )
        
        XCTAssertEqual(cachedState.stateDescription, stateDescription)
        
        XCTAssertEqual(inspectStateOf(cachedState: cachedState).hexString, inspectStateOf(hasher: hasher).hexString)
        
        XCTAssertEqual(inspectStateOf(cachedState: cachedState).hexString, bip340TagPrecomputedState)

        let nonSenseInput = "non-sense data that must be 64 chars or longer, the purpose of which is to change the internal state of hasher"
        XCTAssertGreaterThanOrEqual(nonSenseInput.count, 64) // must be GEQ than 64 because the hasher has an internal buffer with size 64.
        hasher.update(data: nonSenseInput.data(using: .utf8)!)
        XCTAssertNotEqual(inspectStateOf(hasher: hasher).hexString, bip340TagPrecomputedState)

        // Restore
        hasher.restore(cachedState: &cachedState)
        XCTAssertEqual(inspectStateOf(cachedState: cachedState).hexString, bip340TagPrecomputedState)

        XCTAssertEqual(hashBIP340Tag().hexString, Data(hasher.finalize()).hexString)
    }

    func testAssertCachingStateDoesNotHaveSideEffectOnDigests() {
        // https://www.di-mgt.com.au/sha_testvectors.html
       
        var hasher = Shaman256()
        var lastState: Shaman256.CachedState?
        
        let input = String(repeating: "a", count: 1000).data(using: .utf8)!
        for _ in 0..<1000 {
            let cachedState = hasher.updateAndCacheState(data: input)
            XCTAssertNotEqual(cachedState, lastState)
            lastState = cachedState
        }
        
        XCTAssertEqual(Data(hasher.finalize()).hexString, oneMillionADigest)
        
    }
   
    func testAssertCachedStateWithInputOfVariousLength() throws {
        // https://www.di-mgt.com.au/sha_testvectors.html
        let length = 1_000_000
        
        for bytesLeft in 1..<100 {
            var referenceHasher = Shaman256()
            var hasherUnderTest = Shaman256()
            
            let initialInput = String(repeating: "a", count: length - bytesLeft).data(using: .utf8)!
            var cachedMidState = referenceHasher.updateAndCacheState(data: initialInput)
            let remainingInput = String(repeating: "a", count: bytesLeft).data(using: .utf8)!
            
            XCTAssertEqual(initialInput.count + remainingInput.count, length)
            
            hasherUnderTest.restore(cachedState: &cachedMidState)
            hasherUnderTest.update(data: remainingInput)
            XCTAssertEqual(Data(hasherUnderTest.finalize()).hexString, oneMillionADigest)
            referenceHasher.update(data: remainingInput)
            XCTAssertEqual(Data(referenceHasher.finalize()).hexString, oneMillionADigest)
        }
    }
    
    func testShortInput() throws {
        var hasher = Shaman256()
        
        let input = "short".data(using: .utf8)!
        
        var cachedState = hasher.updateAndCacheState(
            data: input
        )
        
        hasher.update(data: " input".data(using: .utf8)!)
        
        // Soundness check...
        XCTAssertEqual(Data(hasher.finalize()).hexString, Data(Shaman256.hash(data: "short input".data(using: .utf8)!)).hexString)
        
        // Actual check
        var otherHasher = Shaman256()
        otherHasher.restore(cachedState: &cachedState)
        otherHasher.update(data: " input".data(using: .utf8)!)
        XCTAssertEqual(Data(otherHasher.finalize()).hexString, Data(Shaman256.hash(data: "short input".data(using: .utf8)!)).hexString)
    }
}
private let oneMillionADigest = "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"
private let bip340TagPrecomputedState = "46615b35f4bfbff79f8dc67183627ab3602171805735866121a29e5468b07b4c"
private let bip340Tag = "BIP0340/nonce"
private extension ShamanTests {
    
    
    func hashBIP340Tag() -> Data {
        nestedHash(tag: bip340Tag)
    }
    
    /// Computes: SHA( SHA(tag) || SHA(tag))
    func nestedHash(tag: String) -> Data {
        let hashed = Data(Shaman256.hash(data: tag.data(using: .utf8)!))
        return Data(Shaman256.hash(data: Data(hashed + hashed)))
    }
}
