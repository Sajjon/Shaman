# Shaman 🧙🏾

_Shaman_ is a _special purpose_ SHA-256 hasher that offers ability to **restore previous state**.

_Shaman_ is Swift wrapper around the [SHA-256 implementation in _libsecp256k1_ (bitcoin-core/secp256k1)](https://github.com/bitcoin-core/secp256k1).

The hasher type is named _Shaman256_ in order to avoid name conflict with [CryptoKit's `SHA256` hasher](https://developer.apple.com/documentation/cryptokit/sha256).

The _Shaman256_ hasher conforms to [CryptoKit's `HashFunction`](https://developer.apple.com/documentation/cryptokit/hashfunction) and produces digests of type _Shaman256.Digest_, which conforms to [CryptoKit's `Digest`](https://developer.apple.com/documentation/cryptokit/digest) protocol.

# Usage

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

# Why?
SHA-256 implementations are usually very fast. You probably do not need to use _Shaman_, you should prefer using [CryptoKit's `SHA256` hasher](https://developer.apple.com/documentation/cryptokit/sha256). However, under some rare circumstances you might benefit from being able to restore a SHA256's internal state.

## Example 
One example of where it is very beneficial to be able to restore state if a hasher is is Proof-of-Work (PoW) work. 

In PoW we might need to iterate hashing the same input data hundreds of thousands of times, or even millions of times.

Even though one run of SHA256 of that fixed input data is fast, it is wasteful to compute it many many times over. Here is where Shaman shines!
