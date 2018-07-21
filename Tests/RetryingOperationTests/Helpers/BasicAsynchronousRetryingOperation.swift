/*
 * BasicAsynchronousRetryingOperation.swift
 * RetryingOperation
 *
 * Created by François Lamboley on 1/19/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation
import RetryingOperation



class BasicAsynchronousRetryingOperation : RetryingOperation {
	
	let nRetries: Int
	var checkStr = ""
	
	private var nStart = 0
	
	init(nRetries r: Int) {
		nRetries = r
	}
	
	override func startBaseOperation(isRetry: Bool) {
		nStart += 1
		checkStr += "."
		DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 0.25) {
			if self.nStart <= self.nRetries {self.baseOperationEnded(needsRetryIn: 0.1)}
			else                            {self.baseOperationEnded()}
		}
	}
	
	override var isAsynchronous: Bool {
		return true
	}
	
}
