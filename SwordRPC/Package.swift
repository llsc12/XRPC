// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwordRPC",
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "SwordRPC",
      targets: ["SwordRPC"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Kitura/BlueSocket", from: "2.0.0")
  ],
  targets: [
    .target(
      name: "SwordRPC",
      dependencies: [
        .product(name: "Socket", package: "BlueSocket")
      ]
    )
  ]
)
