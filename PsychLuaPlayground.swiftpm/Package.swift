// swift-tools-version: 5.8
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "PsychLuaPlayground",
    platforms: [.iOS("16.0")],
    products: [
        .iOSApplication(
            name: "PsychLuaPlayground",
            targets: ["AppModule"],
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .cloud),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [.portrait, .landscapeRight, .landscapeLeft]
        )
    ],
    targets: [
        // Lua 5.1.5 の公式 C ソース（setup.sh が CLua/ に配置する）
        .target(name: "CLua", path: "CLua"),
        .executableTarget(name: "AppModule", dependencies: ["CLua"], path: ".",
                          exclude: ["CLua", "setup.sh", "README.md"])
    ]
)
