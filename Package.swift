// swift-tools-version:5.0
import PackageDescription


let package = Package(
	name: "RetryingOperation",
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
