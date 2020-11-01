// swift-tools-version:5.1
import PackageDescription


let package = Package(
	name: "RetryingOperation",
	products: [
		.library(name: "RetryingOperation", targets: ["RetryingOperation"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log.git", from: "1.2.0")
	],
	targets: [
		.target(name: "RetryingOperation", dependencies: [
			.product(name: "Logging", package: "swift-log")
		]),
		.testTarget(name: "RetryingOperationTests", dependencies: ["RetryingOperation"])
	]
)
