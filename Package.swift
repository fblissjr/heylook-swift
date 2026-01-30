// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HeyLook",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "HeyLook", targets: ["HeyLook"])
    ],
    dependencies: [
        .package(path: "coderef/mlx-swift-lm"),
    ],
    targets: [
        .executableTarget(
            name: "HeyLook",
            dependencies: [
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
            ]
        )
    ]
)
