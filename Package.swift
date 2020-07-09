// swift-tools-version:5.0
import PackageDescription


let package = Package(
	name: "RetryingOperation",
	platforms: [
		.macOS(.v10_10),
		.iOS(.v8),
		.tvOS(.v9),
		.watchOS(.v2)
	],
	products: [
		.library(name: "RetryingOperation", targets: ["RetryingOperation"]),
	],
	dependencies: [
		.package(url: "https://github.com/happn-tech/DummyLinuxOSLog.git", from: "1.0.0")
	],
	targets: [
		.target(name: "RetryingOperation", dependencies: ["DummyLinuxOSLog"]),
		.testTarget(name: "RetryingOperationTests", dependencies: ["RetryingOperation"])
	]
)
