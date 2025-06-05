// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "LilithOS",
  platforms: [
    .iOS(.v17)
  ],
  products: [
    .library(
      name: "LilithOS",
      targets: ["LilithOS"]
    )
  ],
  dependencies: [
    // Add any external dependencies here
  ],
  targets: [
    .target(
      name: "LilithOS",
      dependencies: [],
      path: "Sources"
    ),
    .testTarget(
      name: "LilithOSTests",
      dependencies: ["LilithOS"],
      path: "Tests"
    )
  ]
) 