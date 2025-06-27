// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "LilithOS",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)  // Add macOS support for testing
  ],
  products: [
    .library(
      name: "LilithOS",
      targets: ["LilithOS"]
    ),
    .executable(
      name: "LilithOSApp",
      targets: ["LilithOSApp"]
    )
  ],
  dependencies: [
    // Add any external dependencies here
  ],
  targets: [
    .target(
      name: "LilithOS",
      dependencies: [],
      path: "Sources",
      exclude: ["App"]
    ),
    .executableTarget(
      name: "LilithOSApp",
      dependencies: ["LilithOS"],
      path: "Sources/App"
    ),
    .testTarget(
      name: "LilithOSTests",
      dependencies: ["LilithOS"],
      path: "Tests"
    )
  ]
) 