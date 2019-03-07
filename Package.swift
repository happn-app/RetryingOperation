// swift-tools-version:4.0

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
