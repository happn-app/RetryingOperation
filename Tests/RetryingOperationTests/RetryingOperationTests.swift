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
	
	func testBasicSynchronousRetryingOperation() {
		let op = BasicSynchronousRetryingOperation()
		operationQueue.addOperation(op)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(op.checkStr, "..")
	}
	
	func testBasicAsynchronousRetryingOperation() {
		let op = BasicAsynchronousRetryingOperation()
		self.operationQueue.addOperation(op)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(op.checkStr, "..")
	}
	
	func testBasicSynchronousRetryableOperationInWrapper() {
		let op = BasicSynchronousRetryableOperation(nStart: 1, checkStr: "")
		let rop = RetryableOperationWrapper(baseOperation: op, baseOperationQueue: nil)
		self.operationQueue.addOperation(rop)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(rop.currentBaseOperation.checkStr, "..")
	}
	
	func testCancelledBasicSynchronousRetryableOperationInWrapper() {
		let op = BasicSynchronousRetryableOperation(nStart: 1, checkStr: "")
		let rop = RetryableOperationWrapper(baseOperation: op, baseOperationQueue: nil)
		self.operationQueue.addOperation(rop)
		op.cancel()
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(rop.currentBaseOperation.checkStr, ".")
	}
	
	/* Fill this array with all the tests to have Linux testing compatibility. */
	static var allTests = [
		("testBasicSynchronousRetryingOperation", testBasicSynchronousRetryingOperation),
		("testBasicAsynchronousRetryingOperation", testBasicAsynchronousRetryingOperation),
		("testBasicSynchronousRetryableOperationInWrapper", testBasicSynchronousRetryableOperationInWrapper),
		("testCancelledBasicSynchronousRetryableOperationInWrapper", testCancelledBasicSynchronousRetryableOperationInWrapper)
	]
	
}
