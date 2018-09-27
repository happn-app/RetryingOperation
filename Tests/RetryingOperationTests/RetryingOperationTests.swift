import XCTest
@testable import RetryingOperation



class RetryingOperationTests: XCTestCase {
	
	let operationQueue = OperationQueue()
	
	override func setUp() {
		super.setUp()
		
		operationQueue.maxConcurrentOperationCount = 1
	}
	
	override func tearDown() {
		operationQueue.cancelAllOperations()
		operationQueue.waitUntilAllOperationsAreFinished()
		
		super.tearDown()
	}
	
	func testBasicSynchronousRetryingOperationNoRetries() {
		let op = BasicSynchronousRetryingOperation(nRetries: 0)
		operationQueue.addOperation(op)
		operationQueue.waitUntilAllOperationsAreFinished() /* Works on Linux too because op is synchronous. */
		XCTAssertEqual(op.checkStr, ".")
	}
	
	func testBasicAsynchronousRetryingOperationNoRetries() {
		let op = BasicAsynchronousRetryingOperation(nRetries: 0)
		operationQueue.addOperation(op)
		#if !os(Linux)
			operationQueue.waitUntilAllOperationsAreFinished()
		#else
			/* OperationsQueue’s waitUntilAllOperationsAreFinished does not work
			 * for async operations on Linux… */
			op.waitUntilFinished()
		#endif
		XCTAssertEqual(op.checkStr, ".")
	}
	
	#if !os(Linux)
	func testBasicSynchronousRetryableOperationInWrapperNoRetries() {
		let op = BasicSynchronousRetryableOperation(nRetries: 0, nStart: 1, checkStr: "")
		let rop = RetryableOperationWrapper(baseOperation: op, baseOperationQueue: nil)
		operationQueue.addOperation(rop)
		operationQueue.waitUntilAllOperationsAreFinished() /* Works on Linux too because op is synchronous. */
		XCTAssertEqual(rop.currentBaseOperation.checkStr, ".")
	}
	#endif
	
	func testBasicSynchronousRetryingOperation1Retry() {
		let op = BasicSynchronousRetryingOperation(nRetries: 1)
		operationQueue.addOperation(op)
		operationQueue.waitUntilAllOperationsAreFinished() /* Works on Linux too because op is synchronous. */
		XCTAssertEqual(op.checkStr, "..")
	}
	
	func testBasicAsynchronousRetryingOperation1Retry() {
		let op = BasicAsynchronousRetryingOperation(nRetries: 1)
		operationQueue.addOperation(op)
		#if !os(Linux)
			operationQueue.waitUntilAllOperationsAreFinished()
		#else
			/* OperationsQueue’s waitUntilAllOperationsAreFinished does not work
			 * for async operations on Linux… */
			op.waitUntilFinished()
		#endif
		XCTAssertEqual(op.checkStr, "..")
	}
	
	#if !os(Linux)
	func testBasicSynchronousRetryableOperationInWrapper1Retry() {
		let op = BasicSynchronousRetryableOperation(nRetries: 1, nStart: 1, checkStr: "")
		let rop = RetryableOperationWrapper(baseOperation: op, baseOperationQueue: nil)
		operationQueue.addOperation(rop)
		operationQueue.waitUntilAllOperationsAreFinished() /* Works on Linux too because op is synchronous. */
		XCTAssertEqual(rop.currentBaseOperation.checkStr, "..")
	}
	
	func testCancelledBasicSynchronousRetryableOperationInWrapper1Retry() {
		let op = BasicSynchronousRetryableOperation(nRetries: 1, nStart: 1, checkStr: "")
		let rop = RetryableOperationWrapper(baseOperation: op, baseOperationQueue: nil)
		operationQueue.addOperation(rop)
		op.cancel()
		operationQueue.waitUntilAllOperationsAreFinished() /* Works on Linux too because op is synchronous. */
		XCTAssertEqual(rop.currentBaseOperation.checkStr, ".")
	}
	#endif
	
	/* Fill this array with all the tests to have Linux testing compatibility. */
	static var allTests = [
		("testBasicSynchronousRetryingOperationNoRetries", testBasicSynchronousRetryingOperationNoRetries),
		("testBasicAsynchronousRetryingOperationNoRetries", testBasicAsynchronousRetryingOperationNoRetries),
//		("testBasicSynchronousRetryableOperationInWrapperNoRetries", testBasicSynchronousRetryableOperationInWrapperNoRetries),
		("testBasicSynchronousRetryingOperation1Retry", testBasicSynchronousRetryingOperation1Retry),
		("testBasicAsynchronousRetryingOperation1Retry", testBasicAsynchronousRetryingOperation1Retry),
//		("testBasicSynchronousRetryableOperationInWrapper1Retry", testBasicSynchronousRetryableOperationInWrapper1Retry),
//		("testCancelledBasicSynchronousRetryableOperationInWrapper1Retry", testCancelledBasicSynchronousRetryableOperationInWrapper1Retry)
	]
	
}
