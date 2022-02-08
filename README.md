# Shaman 🧙🏾
_Shaman_ is Swift wrapper around the [SHA-256 implementation in libsecp256k1 (bitcoin-core/secp256k1)](https://github.com/bitcoin-core/secp256k1) with feature of initializing a SHA256 hasher with some precomputed midstate. The actual hasher is named _Shaman256_ in order to avoid name conflict with swift-crypto / CryptoKit's _SHA256_ hasher.

The _Shaman256_ hasher conforms to [CryptoKit's HashFunction](https://developer.apple.com/documentation/cryptokit/hashfunction) and produces digests of type [Shaman256.Digest], which conforms to swift-crypto / CryptoKit's [`Digest`](https://developer.apple.com/documentation/cryptokit/digest) protocol.

## Usage

```swift
var hasher = Shaman256()

// Tag (cache) some important state
let tag = hasher.update(data: "some input".data(using: .utf8)!, tag: "state I wanna cache") // returned type: `Shaman256.Tag`

// Later: Change hasher to some "bad" state
hasher.update(data: "input resulting in unwanted state".data(using: .utf8)!)

// Later: Restore the internal state of the hasher
hasher.restore(tag: tag)

assert(hasher.finalize() == Shaman256.hash(data: "some input".data(using: .utf8)!) // true
```

