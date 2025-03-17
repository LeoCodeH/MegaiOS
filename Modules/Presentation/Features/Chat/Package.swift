// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "Chat",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Chat",
            targets: ["Chat"]
        )
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../../Repository/ChatRepo"),
        .package(path: "../../../Presentation/MEGAL10n"),
        .package(path: "../../MEGAPresentation"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "Chat",
            dependencies: [
                "MEGADomain",
                "ChatRepo",
                "MEGAL10n",
                "MEGASwiftUI"
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "ChatTests",
            dependencies: [
                "Chat",
                .product(
                    name: "MEGATest",
                    package: "MEGATest"
                ),
                .product(
                    name: "MEGADomainMock",
                    package: "MEGADomain"
                ),
                .product(
                    name: "MEGAPresentationMock",
                    package: "MEGAPresentation"
                )
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
