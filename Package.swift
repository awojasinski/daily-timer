// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DailyTimer",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TimerCore", targets: ["TimerCore"]),
        .executable(name: "DailyTimer", targets: ["DailyTimer"]),
        .executable(name: "TimerAssets", targets: ["TimerAssets"])
    ],
    targets: [
        .target(name: "TimerCore"),
        .executableTarget(name: "DailyTimer", dependencies: ["TimerCore"], exclude: ["Sounds"]),
        .executableTarget(name: "TimerAssets", path: "Tools/TimerAssets"),
        .testTarget(name: "TimerCoreTests", dependencies: ["TimerCore"]),
        .testTarget(name: "DailyTimerTests", dependencies: ["DailyTimer", "TimerCore"])
    ]
)
