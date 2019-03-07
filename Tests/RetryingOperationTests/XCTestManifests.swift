import XCTest

extension RetryingOperationTests {
    static let __allTests = [
        ("testBasicAsynchronousRetryingOperation1Retry", testBasicAsynchronousRetryingOperation1Retry),
        ("testBasicAsynchronousRetryingOperationNoRetries", testBasicAsynchronousRetryingOperationNoRetries),
        ("testBasicSynchronousRetryableOperationInWrapper1Retry", testBasicSynchronousRetryableOperationInWrapper1Retry),
        ("testBasicSynchronousRetryableOperationInWrapperNoRetries", testBasicSynchronousRetryableOperationInWrapperNoRetries),
        ("testBasicSynchronousRetryingOperation1Retry", testBasicSynchronousRetryingOperation1Retry),
        ("testBasicSynchronousRetryingOperationNoRetries", testBasicSynchronousRetryingOperationNoRetries),
        ("testCancelledBasicSynchronousRetryableOperationInWrapper1Retry", testCancelledBasicSynchronousRetryableOperationInWrapper1Retry),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RetryingOperationTests.__allTests),
    ]
}
#endif
