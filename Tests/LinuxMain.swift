import XCTest

import RetryingOperationTests

var tests = [XCTestCaseEntry]()
tests += RetryingOperationTests.__allTests()

XCTMain(tests)
