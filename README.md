# VouchCore (Swift SDK)

The Swift SDK for the [Vouch Protocol](https://github.com/vouch-protocol/vouch).
A thin, idiomatic layer over the UniFFI bindings to the canonical Rust core
(`vouch-core`), so iOS and macOS apps verify credentials with the exact same
bytes as the TypeScript, Python, Go, JVM, and .NET SDKs. Apache-2.0.

> This repository is a published mirror of the Swift SDK that lives in the Vouch
> monorepo at `sdks/swift/`. It exists because Swift Package Manager requires
> `Package.swift` at the repository root, so the package cannot be imported from
> a subdirectory of the monorepo. The source of truth is the monorepo; changes
> here are synced from it (see `scripts/sync-from-monorepo.sh`).

## What you get

- JCS canonicalization, Ed25519, did:key/multikey
- Data Integrity proofs (`eddsa-jcs-2022`): sign + verify, with validity-window checks
- Post-quantum: ML-DSA-44 and dual proofs (Ed25519 + ML-DSA), plus composite verify
- BitstringStatusList revocation checks

The native core ships as a prebuilt XCFramework hosted on the monorepo's GitHub
releases, so you do not need a Mac or the Rust toolchain to consume this package.

## Install (Swift Package Manager)

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vouch-protocol/vouch-swift.git", from: "0.1.0"),
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "VouchCore", package: "vouch-swift"),
    ]),
]
```

Or in Xcode: File > Add Package Dependencies, then paste
`https://github.com/vouch-protocol/vouch-swift.git`.

## Use

```swift
import VouchCore

let kp = try Vouch.generateEd25519()
let signed = try Vouch.signCredential(
    credentialJson,
    seed: kp.seed,
    verificationMethod: kp.didKey + "#key-1",
    created: "2026-04-26T10:00:00Z"
)
let result = try Vouch.verifyCredential(signed, publicKey: kp.publicKey, now: isoNow)
// result.valid, result.proofValid, result.timeValid
```

Binary values are `Data`; credentials and proofs are JSON `String`s. The lower
level UniFFI functions (`canonicalize(json:)`, `generateEd25519()`, ...) are also
exported directly if you prefer them over the `Vouch` namespace.

## Rebuilding the native core (maintainers)

The vendored binding and the hosted XCFramework are produced from the Rust core.
To rebuild locally on macOS (needs Xcode and the Rust toolchain):

```
./build-xcframework.sh     # -> Frameworks/vouch_coreFFI.xcframework
swift test                 # runs the XCTest suite
```

To consume the locally built framework instead of the hosted release, swap the
remote `binaryTarget(url:checksum:)` in `Package.swift` back to a
`binaryTarget(name:path:)` pointing at `Frameworks/vouch_coreFFI.xcframework`.

## Interop

Output is verified byte-for-byte against the shared cross-language vectors in the
monorepo's `test-vectors/`. A proof built here verifies in every other Vouch SDK.
