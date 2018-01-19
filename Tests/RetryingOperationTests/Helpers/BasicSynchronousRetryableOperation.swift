/*
 * BasicSynchronousRetryableOperation.swift
 * RetryingOperation
 *
 * Created by François Lamboley on 1/19/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation
import RetryingOperation



class BasicSynchronousRetryableOperation : Operation, RetryableOperation {
	
	let nStart: Int
	var checkStr: String
	
	required init(nStart n: Int, checkStr str: String) {
		nStart = n
		checkStr = str
	}
	
	override func main() {
		checkStr += "."
		Thread.sleep(forTimeInterval: 0.25)
	}
	
	func retryHelpers<T>(from wrapper: RetryableOperationWrapper<T>) -> [RetryHelper]? {
		return nStart <= 1 ? [RetryingOperation.TimerRetryHelper(retryDelay: 0.1, retryingOperation: wrapper)] : nil
	}
	
	func operationForRetrying() -> Self {
		return type(of: self).init(nStart: nStart + 1, checkStr: checkStr)
	}
	
}
