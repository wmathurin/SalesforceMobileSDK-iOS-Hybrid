// swift-tools-version: 6.0
import PackageDescription

// SalesforceHybridSDK mixes ObjC and Swift, so it is split into two targets.
// SalesforceFileLogger is pure ObjC.
//
// Header layout uses the same include/ symlink pattern as SalesforceMobileSDK-iOS:
//   libs/<Lib>/<Lib>/include/<Lib>/ contains symlinks to every public .h plus
//   a hand-maintained <Lib>-Swift.h stub that forward-declares @objc Swift types.
//
// Dependency chain:
//   SalesforceFileLogger → SalesforceSDKCommon + CocoaLumberjack
//   SalesforceHybridSDK  → MobileSync + CordovaLib
//   SalesforceHybridSDKSwift → SalesforceHybridSDK (ObjC)

let package = Package(
    name: "SalesforceMobileSDK-iOS-Hybrid",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
    ],
    products: [
        .library(name: "SalesforceHybridSDK",  targets: ["SalesforceHybridSDKSwift"]),
        .library(name: "SalesforceFileLogger",  targets: ["SalesforceFileLogger"]),
    ],
    dependencies: [
        .package(path: "../SalesforceMobileSDK-iOS"),
        .package(path: "external/cordova"),
        .package(path: "external/CocoaLumberjack"),
    ],
    targets: [

        // MARK: - SalesforceHybridSDK (ObjC portion)

        .target(
            name: "SalesforceHybridSDK",
            dependencies: [
                .product(name: "MobileSync",    package: "SalesforceMobileSDK-iOS"),
                .product(name: "CordovaLib",    package: "cordova"),
            ],
            path: "libs/SalesforceHybridSDK/SalesforceHybridSDK",
            exclude: [
                "Classes/SalesforceWebViewCookieManager.swift",
                "Classes/SalesforceHybridSDK-Swift.h",
                "SalesforceHybridSDK.h",
            ],
            sources: ["Classes"],
            resources: [
                .copy("PrivacyInfo.xcprivacy"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Classes"),
                .headerSearchPath("Classes/Plugins"),
                .headerSearchPath("Classes/Plugins/SDKInfo"),
                .headerSearchPath("Classes/Plugins/SFAccountManagerPlugin"),
                .headerSearchPath("Classes/Plugins/SFAdditions"),
                .headerSearchPath("Classes/Plugins/SFForcePlugin"),
                .headerSearchPath("Classes/Plugins/SFMobileSyncPlugin"),
                .headerSearchPath("Classes/Plugins/SFNetworkPlugin"),
                .headerSearchPath("Classes/Plugins/SFOAuthPlugin"),
                .headerSearchPath("Classes/Plugins/SFSmartStore"),
            ]
        ),

        // MARK: - SalesforceHybridSDK (Swift portion)

        .target(
            name: "SalesforceHybridSDKSwift",
            dependencies: [
                "SalesforceHybridSDK",
                .product(name: "SalesforceSDKCore", package: "SalesforceMobileSDK-iOS"),
            ],
            path: "libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes",
            sources: ["SalesforceWebViewCookieManager.swift"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .define("SWIFT_PACKAGE"),
            ]
        ),

        // MARK: - SalesforceFileLogger (pure ObjC)

        .target(
            name: "SalesforceFileLogger",
            dependencies: [
                .product(name: "SalesforceSDKCommon", package: "SalesforceMobileSDK-iOS"),
                .product(name: "CocoaLumberjack",     package: "CocoaLumberjack"),
            ],
            path: "libs/SalesforceFileLogger/SalesforceFileLogger",
            exclude: [
                "SalesforceFileLogger.h",
            ],
            sources: ["Classes"],
            resources: [
                .copy("PrivacyInfo.xcprivacy"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Classes/Logger"),
            ]
        ),
    ]
)
