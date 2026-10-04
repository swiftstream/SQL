// swift-tools-version:6.3

import PackageDescription

let package = Package(
    name: "SQL",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        // 💎 Swift lib that gives an ability to build complex raw SQL-queries in strong-type declarative way
        .library(name: "SQL", targets: ["SQL"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "SQL", dependencies: [], path: "Sources/SQL"),
        .testTarget(name: "SQLTests", dependencies: ["SQL"], path: "Tests/SQLTests"),
    ],
    swiftLanguageModes: [.v6]
)
