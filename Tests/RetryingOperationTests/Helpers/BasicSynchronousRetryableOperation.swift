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

import Foundation
import RetryingOperation



final class BasicSynchronousRetryableOperation : Operation, RetryableOperation {
	
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
