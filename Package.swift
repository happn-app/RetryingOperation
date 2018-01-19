// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription



let package = Package(
	name: "RetryingOperation",
	products: [
		.library(
			name: "RetryingOperation",
			targets: ["RetryingOperation"]
		)
	],
	dependencies: [
	],
	targets: [
		.target(
			name: "RetryingOperation",
			dependencies: []
		),
		.testTarget(
			name: "RetryingOperationTests",
			dependencies: ["RetryingOperation"]
		)
	]
)
