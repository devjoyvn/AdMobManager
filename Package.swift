// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AdMobManager",
  platforms: [.iOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "AdMobManager",
      targets: ["AdMobManager"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(name: "GoogleMobileAds", url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", revision: "11.4.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk", revision: "11.9.0"),
    .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework", revision: "6.15.3"),
    .package(url: "https://github.com/AppsFlyerSDK/appsflyer-apple-purchase-connector", revision: "6.15.3"),
    .package(url: "https://github.com/AppsFlyerSDK/adrevenue-apple-sdk.git", revision: "6.14.3"),
    .package(url: "https://github.com/Kitura/Swift-JWT", revision: "3.6.201")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "AdMobManager",
      dependencies: [
        "GoogleMobileAds",
        .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
        .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
        .product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
        .product(name: "AppsFlyerLib", package: "AppsFlyerFramework"),
        .product(name: "PurchaseConnector", package: "appsflyer-apple-purchase-connector"),
        .product(name: "AppsFlyerAdRevenue", package: "adrevenue-apple-sdk"),
        .product(name: "SwiftJWT", package: "swift-jwt")
      ]
    )
  ]
)
