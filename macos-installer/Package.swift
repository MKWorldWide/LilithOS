// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LilithOSInstaller",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LilithOSInstaller",
            targets: ["LilithOSInstaller"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LilithOSInstaller",
            path: ".",
            exclude: ["build_and_run.sh", "README.md", "Package.swift"],
            sources: ["LilithOSInstaller.swift"]
        )
    ]
) 