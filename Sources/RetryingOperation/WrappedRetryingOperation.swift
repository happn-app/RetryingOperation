/*
 * WrappedRetryingOperation.swift
 * Happn
 *
 * Created by François Lamboley on 12/11/15.
 * Copyright © 2015 happn. All rights reserved.
 */

import Foundation



#if !os(Linux)

/* Not supported w/ 4.2 on Linux yet. (Apparently, this is touchy on macOS too…)
 * On Swift 5, will be officially supported and have the following syntax:
 *    protocol RetryableOperation : Operation */
public protocol RetryableOperation where Self : Operation {
	
	/* I’d like to add “where T : Self” so that clients of the protocol know
	 * ther're given an object kind of class Self, but I get an error:
	 *    Type ‘T’ constrainted to non-protocol, non-class type ‘Self’
	 *
	 * I could also remove the T type and set wrapper’s type to
	 * RetryableOperationWrapper<Self>, but this forces the clients of the
	 * protocol to be final, so it is not ideal either... */
	func retryHelpers<T>(from wrapper: RetryableOperationWrapper<T>) -> [RetryHelper]?
	
	/** Must return a valid retryable operation. You cannot return self here. */
	func operationForRetrying() throws -> Self
	
}


/**
An operation that can run an operation conforming to the RetryableOperation
protocol and retry the operation depending on the protocol implementation. */
public final class RetryableOperationWrapper<T> : RetryingOperation where T : RetryableOperation {
	
	public let originalBaseOperation: T
	public private(set) var currentBaseOperation: T
	
	/**
   The queue on which the base operation(s) will run. Do not set to the queue on
	which the retry operation wrapper runs unless you really know what you're
	doing.
	
	If nil (default), the base operation will not be launched in a queue. */
	public let baseOperationQueue: OperationQueue?
	
	/** If < 0, the operation is retried indefinitely. */
	public let maximumNumberOfRetries: Int
	
	public init(maximumNumberOfRetries maxRetry: Int = -1, baseOperation: T, baseOperationQueue queue: OperationQueue? = nil) {
		maximumNumberOfRetries = maxRetry
		
		originalBaseOperation = baseOperation
		currentBaseOperation = baseOperation
		
		baseOperationQueue = queue
	}
	
	public override func startBaseOperation(isRetry: Bool) {
		/* No need to call super. */
		
		if isRetry {
			guard let op: T = try? currentBaseOperation.operationForRetrying() else {return baseOperationEnded()}
			currentBaseOperation = op
		}
		
		if let q = baseOperationQueue {q.addOperation(currentBaseOperation)}
		else                          {currentBaseOperation.start()}
		currentBaseOperation.waitUntilFinished()
		
		let canRetry = (self.maximumNumberOfRetries < 0 || self.numberOfRetries! < self.maximumNumberOfRetries)
		self.baseOperationEnded(retryHelpers: canRetry ? self.currentBaseOperation.retryHelpers(from: self) : nil)
	}
	
	public override func cancelBaseOperation() {
		currentBaseOperation.cancel()
	}
	
	public override var isAsynchronous: Bool {
		return false
	}
	
}

#endif
