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
	
	var checkStr = ""
	
	private var nStart = 0
	
	override func startBaseOperation(isRetry: Bool) {
		nStart += 1
		checkStr += "."
		DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + 0.25) {
			if self.nStart <= 1 {self.baseOperationEnded(needsRetryIn: 0.1)}
			else                {self.baseOperationEnded()}
		}
	}
	
	override var isAsynchronous: Bool {
		return true
	}
	
}
