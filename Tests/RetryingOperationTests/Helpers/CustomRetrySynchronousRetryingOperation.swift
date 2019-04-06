/*
Copyright 2019 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import Foundation
import RetryingOperation



class CustomRetrySynchronousRetryingOperation : RetryingOperation {
	
	var checkStr = ""
	let immediateCancellation: Bool
	let retryHelper: CustomRetryHelper /* Only used to test whether the retry helper is properly setup */
	
	var hasEndedBaseOperation: Bool {
		return _hasEndedBaseOperationQueue.sync{ _hasEndedBaseOperation }
	}
	
	private var _hasEndedBaseOperation = false
	private var _hasEndedBaseOperationQueue = DispatchQueue(label: "has ended base operation sync queue")
	
	init(immediateCancellation c: Bool = false) {
		retryHelper = CustomRetryHelper()
		immediateCancellation = c
		
		super.init()
	}
	
	override func startBaseOperation(isRetry: Bool) {
		if immediateCancellation {cancel()}
		
		checkStr += "."
		Thread.sleep(forTimeInterval: 0.25)
		if !isRetry {self.baseOperationEnded(retryHelpers: [retryHelper])} /* The retry helper won’t do anything; the operation will be retrying from the test directly. */
		else        {self.baseOperationEnded()}
		
		_hasEndedBaseOperationQueue.sync{ _hasEndedBaseOperation = true }
	}
	
	override var isAsynchronous: Bool {
		return false
	}
	
}


class CustomRetryHelper : RetryHelper {
	
	var setupCheckStr = ""
	var teardownCheckStr = ""
	
	func setup() {
		setupCheckStr += "."
	}
	
	func teardown() {
		teardownCheckStr += "."
	}
	
}
