/*
 * BasicSynchronousRetryableOperation.swift
 * RetryingOperation
 *
 * Created by François Lamboley on 1/19/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation
import RetryingOperation



#if !os(Linux)

class BasicSynchronousRetryableOperation : Operation, RetryableOperation {
	
	let nRetries: Int
	var checkStr: String
	
	private let nStart: Int
	
	required init(nRetries r: Int, nStart n: Int, checkStr str: String) {
		nStart = n
		nRetries = r
		checkStr = str
	}
	
	override func main() {
		checkStr += "."
		Thread.sleep(forTimeInterval: 0.25)
	}
	
	func retryHelpers<T>(from wrapper: RetryableOperationWrapper<T>) -> [RetryHelper]? {
		return nStart <= nRetries ? [RetryingOperation.TimerRetryHelper(retryDelay: 0.1, retryingOperation: wrapper)] : nil
	}
	
	func operationForRetrying() -> Self {
		return type(of: self).init(nRetries: nRetries, nStart: nStart + 1, checkStr: checkStr)
	}
	
}

#endif
