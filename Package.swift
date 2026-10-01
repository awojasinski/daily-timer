// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TinyToast",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ToastCore", targets: ["ToastCore"]),
        .executable(name: "TinyToast", targets: ["TinyToast"]),
        .executable(name: "ToastAssets", targets: ["ToastAssets"])
    ],
    targets: [
        .target(name: "ToastCore"),
        .target(name: "ToastArt", dependencies: ["ToastCore"]),
        .executableTarget(name: "TinyToast", dependencies: ["ToastCore", "ToastArt"]),
        .executableTarget(name: "ToastAssets", dependencies: ["ToastCore", "ToastArt"], path: "Tools/ToastAssets"),
        .testTarget(name: "ToastCoreTests", dependencies: ["ToastCore", "ToastArt"]),
        .testTarget(name: "TinyToastTests", dependencies: ["TinyToast", "ToastCore"])
    ]
)
