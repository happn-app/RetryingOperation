/*
Copyright 2018 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import XCTest
@testable import RetryingOperation



class RetryingOperationTests : XCTestCase {
	
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
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(op.checkStr, ".")
	}
	
	func testBasicAsynchronousRetryingOperationNoRetries() {
		let op = BasicAsynchronousRetryingOperation(nRetries: 0)
		operationQueue.addOperation(op)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(op.checkStr, ".")
	}
	
	func testBasicSynchronousRetryableOperationInWrapperNoRetries() {
		let op = BasicSynchronousRetryableOperation(nRetries: 0, nStart: 1, checkStr: "")
		let rop = RetryableOperationWrapper(baseOperation: op, baseOperationQueue: nil)
		operationQueue.addOperation(rop)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(rop.currentBaseOperation.checkStr, ".")
	}
	
	func testBasicSynchronousRetryingOperation1Retry() {
		let op = BasicSynchronousRetryingOperation(nRetries: 1)
		operationQueue.addOperation(op)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(op.checkStr, "..")
	}
	
	func testBasicAsynchronousRetryingOperation1Retry() {
		let op = BasicAsynchronousRetryingOperation(nRetries: 1)
		operationQueue.addOperation(op)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(op.checkStr, "..")
	}
	
	func testBasicSynchronousRetryableOperationInWrapper1Retry() {
		let op = BasicSynchronousRetryableOperation(nRetries: 1, nStart: 1, checkStr: "")
		let rop = RetryableOperationWrapper(baseOperation: op, baseOperationQueue: nil)
		operationQueue.addOperation(rop)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(rop.currentBaseOperation.checkStr, "..")
	}
	
	func testCancelledBasicSynchronousRetryableOperationInWrapper1Retry() {
		let op = BasicSynchronousRetryableOperation(nRetries: 1, nStart: 1, checkStr: "")
		let rop = RetryableOperationWrapper(baseOperation: op, baseOperationQueue: nil)
		op.cancel()
		operationQueue.addOperation(rop)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(rop.currentBaseOperation.checkStr, ".")
	}
	
	func testCustomRetrySynchronousRetryingOperation() {
		let op = CustomRetrySynchronousRetryingOperation()
		operationQueue.addOperation(op)
		/* There are probably cleverer ways to do this, but we don’t care about optimizing anything here; we’re in a test... */
		DispatchQueue(label: "launch retry queue").async{
			var hasRetried = false
			while !hasRetried {
				Thread.sleep(forTimeInterval: 0.1)
				if op.hasEndedBaseOperation {
					hasRetried = true
					op.retryNow()
				}
			}
		}
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(op.checkStr, "..")
		XCTAssertEqual(op.retryHelper.setupCheckStr, ".")
		XCTAssertEqual(op.retryHelper.teardownCheckStr, ".")
	}
	
	func testCustomRetryCancelledSynchronousRetryingOperation() {
		let op = CustomRetrySynchronousRetryingOperation(immediateCancellation: true)
		operationQueue.addOperation(op)
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(op.checkStr, ".")
		XCTAssertEqual(op.retryHelper.setupCheckStr, "")
		XCTAssertEqual(op.retryHelper.teardownCheckStr, "")
	}
	
	func testCustomRetryCancelledSynchronousRetryingOperationBis() {
		let op = CustomRetrySynchronousRetryingOperation()
		operationQueue.addOperation(op)
		/* There are probably cleverer ways to do this, but we don’t care about optimizing anything here; we’re in a test... */
		DispatchQueue(label: "launch retry queue").async{
			var hasCancelled = false
			while !hasCancelled {
				Thread.sleep(forTimeInterval: 0.1)
				if op.hasEndedBaseOperation {
					hasCancelled = true
					op.cancel()
				}
			}
		}
		operationQueue.waitUntilAllOperationsAreFinished()
		XCTAssertEqual(op.checkStr, ".")
		XCTAssertEqual(op.retryHelper.setupCheckStr, ".")
		XCTAssertEqual(op.retryHelper.teardownCheckStr, ".")
	}
	
}
