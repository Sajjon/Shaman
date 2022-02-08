# Shaman 🧙🏾

_Shaman_ is a _special purpose_ SHA-256 hasher that offers ability to **restore previous state**.

_Shaman_ is Swift wrapper around the [SHA-256 implementation in _libsecp256k1_ (bitcoin-core/secp256k1)](https://github.com/bitcoin-core/secp256k1).

The hasher type is named _Shaman256_ in order to avoid name conflict with [CryptoKit's `SHA256` hasher][cksha256].

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
SHA-256 implementations are usually very fast. You probably do not need to use _Shaman_, you should prefer using [CryptoKit's `SHA256` hasher][cksha256]. However, under some rare circumstances you might benefit from being able to restore a SHA256's internal state.

## Example 
One example of where it is very beneficial to be able to restore state if a hasher is is [Proof-of-Work (PoW)](https://en.wikipedia.org/wiki/Proof_of_work) work. 

In PoW we might need to iterate hashing the same input data appended with some increasing [nonce](https://en.wikipedia.org/wiki/Cryptographic_nonce) hundreds of thousands of times, or even millions of times or more. 

Since:

```swift
hasher.update(data: input || nonce)
``` 

is the same as:

```swift
hasher.update(data: input)
hasher.update(data: nonce)
```

we can cache the result of `hasher.update(data: input)` and just calculate `hasher.update(data: nonce)` in very iteration increasing `nonce`, **which requires restoring the internal state of the hasher to the state produced by `hasher.update(data: input)` in between iterations**.

Since  [CryptoKit's `SHA256` hasher][cksha256] does not offer this functionality (neither does [krzyzanowskim/CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift/blob/main/Sources/CryptoSwift/SHA2.swift)), I decided to write this library.

## Performance Boost
Thanks to being able to cache reused SHA256 state, we see a ~10% performance boost for nested SHA256 PoW and a ~35% performance boost for SHA256 (once).

I've tested _Shaman_ in [`Arbeta`][arbeta] which is a simple Proof of Work implementation using _Shaman_.

```swift
let vector = (
    expectedResultingNonce: 2_317_142_010, 
    seed: "1e7d73d01f09ef9bd60de85b3aa7799531342dc6211f43e1a9b253725d8ee4e7", 
    difficulty: 32
)
```

Running that vector with a `HashPOWWorker<Shaman256>` worker with cache enabled (default) yields:
```sh
✅ PoW usedCache=true took 1760s.
```

And with cache disabled (really just relevant for testing):
```sh
✅ PoW usedCache=false took 2700s.
```

Which results in a 35% performance boost.


[cksha256]: https://developer.apple.com/documentation/cryptokit/sha256
[arbeta]: https://github.com/Sajjon/Arbeta
