// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Shaman",
    
    platforms: [
      .macOS(.v11),
      .iOS(.v13),
    ],
    
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Shaman",
            targets: ["Shaman"]),
    ],
    dependencies: [
        // SHA256.Digest so our API is compatible with swift-crypto
        .package(url: "https://github.com/apple/swift-crypto.git", "2.0.0" ..< "3.0.0"),
        
    ],
    targets: [
 
        .target(
            name: "secp256k1",
            sources: ["src"],
            cSettings: [
                .headerSearchPath("secp256k1/include")
            ]
        ),
        
        .target(
            name: "Shaman",
            dependencies: [
                "secp256k1",
                // `SHA256.Digest`, `HashFunction`
                .product(name: "Crypto", package: "swift-crypto"),
            ]),
        
        .testTarget(
            name: "ShamanTests",
            dependencies: ["Shaman"]),
    ]
)
