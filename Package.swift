// swift-tools-version:5.0
import PackageDescription


let package = Package(
	name: "RetryingOperation",
	products: [
		.library(name: "RetryingOperation", targets: ["RetryingOperation"]),
	],
	targets: [
		.target(name: "RetryingOperation", dependencies: []),
		.testTarget(name: "RetryingOperationTests", dependencies: ["RetryingOperation"])
	]
)
