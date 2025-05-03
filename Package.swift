// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "WheelPicker",
                      platforms: [
                          .iOS(.v16), .watchOS(.v9), .macCatalyst(.v16), .macOS(.v13)
                      ],
                      products: [
                          .library(name: "WheelPicker",
                                   targets: ["WheelPicker"])
                      ],
                      targets: [
                          .target(name: "WheelPicker",
                                  dependencies: [])
                      ])
