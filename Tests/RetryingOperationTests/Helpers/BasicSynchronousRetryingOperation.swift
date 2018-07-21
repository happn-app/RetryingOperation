/*
 * BasicSynchronousRetryingOperation.swift
 * RetryingOperation
 *
 * Created by François Lamboley on 1/19/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation
import RetryingOperation



class BasicSynchronousRetryingOperation : RetryingOperation {
	
	let nRetries: Int
	var checkStr = ""
	
	private var nStart = 0
	
	init(nRetries r: Int) {
		nRetries = r
	}
	
	override func startBaseOperation(isRetry: Bool) {
		nStart += 1
		checkStr += "."
		Thread.sleep(forTimeInterval: 0.25)
		if nStart <= nRetries {baseOperationEnded(needsRetryIn: 0.1)}
		else                  {baseOperationEnded()}
	}
	
	override var isAsynchronous: Bool {
		return false
	}
	
}
