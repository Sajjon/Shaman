# Shaman 🧙🏾
_Shaman_ is Swift wrapper around the [SHA-256 implementation in libsecp256k1 (bitcoin-core/secp256k1)](https://github.com/bitcoin-core/secp256k1) with feature of initializing a SHA256 hasher with some precomputed midstate.

The SHA256 hasher conforms to [CryptoKit's HashFunction](https://developer.apple.com/documentation/cryptokit/hashfunction) and produces digests of type [SHA256Digest](https://developer.apple.com/documentation/cryptokit/sha256digest), making it compatible with CryptoKit APIs.
