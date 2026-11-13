// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NavidadBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NavidadBar", targets: ["NavidadBar"])
    ],
    targets: [
        .executableTarget(
            name: "NavidadBar",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("QuartzCore")
            ]
        )
    ]
)
