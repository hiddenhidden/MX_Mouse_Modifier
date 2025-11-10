// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MXMasterConfig",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "hid-logger", targets: ["HIDLogger"]),
        .executable(name: "mxmasterd", targets: ["MXMasterDaemon"])
    ],
    targets: [
        .executableTarget(
            name: "HIDLogger",
            path: "Sources/HIDLogger",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "MXMasterDaemon",
            path: "Sources/MXMasterDaemon",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
