/*
 * RetryingOperation.swift
 * Happn
 *
 * Created by François Lamboley on 12/11/15.
 * Copyright © 2015 happn. All rights reserved.
 */

import Foundation

import os.log



/**
# Retrying Operations

## What Is It?

An abstract class for retrying operations. The idea is to provide a clean and
easy way to create retrying operations. For instance, if you make an operation
to fetch some network resources, the operation might fail because there is no
Internet right now. However, Internet might be back soon! Instead of bothering
your user by telling him there’s no net and he should retry, you might want to
wait a few seconds and retry the request(s).

The retrying operation class gives you a way to easily handle the retrying
process.

_Note_: Cancelled operations are not retried.

## How to Use It?

`RetryingOperation` is an abstract class. In order to use it you must subclass
it.

Usually, when subclassing `Operation`, you either subclass `start()`,
`executing`, `finished` and `asynchronous` if you want to write an asynchronous
operation, or simply `main()` for synchronous operations.

To subclass `RetryingOperation` correctly, you only have to subclass
`startBaseOperation()` (and `asynchronous` if you want an asynchronous
operation). In your implementation, you are responsible for starting your
operation, but you do not have to worry about managing the `executing` and
`finished` properties of the operation: they are managed for you.

When your operation is finished, you must call `baseOperationEnded()`. The
parameters you pass to this method will determine whether the operation should
be retried and the retry delay. The method must be called even if the operation
is finished because the operation was cancelled (even though the retry parameter
is ignored if the operation is cancelled). Indeed, if your operation is
synchronous, the method must be called before the `startBaseOperation()`
returns…

When your operation is in the process of waiting for a retry, you can call
`retryNow()` or `retry(withHelpers:)` to bypass the current retry helpers and
either retry now or setup new helpers. _Note_: If the base operation is already
running, never started or is finished when these methods are called, nothing is
done, but a warning is printed in the logs.

`startBaseOperation()` and `cancelBaseOperation()` will be called from the same,
private GCD queue. Do **not** make any other assumptions thread-wise about these
methods when you're called. Also note you might not have a working run-loop. If
you're writing an asynchronous operation, you **must** leave the method as soon
as possible, exactly like you'd do when overwriting `start()`.

## What About Operations I Don't Own?

Use case: I'm using a framework which provide nice operations. I would want to
make these operations retryable, but I cannot make them inherit from
`RetryingOperation` as I do not own them. What can I do?

A solution is to use `RetryableOperationWrapper`. See the doc of this class
for more information. */
open class RetryingOperation : Operation {
	
	public enum RetryingOperationState {
		
		case inited
		case running(Int) /* The value is the number of retries (0 for first try) */
		case waitingToRetry(Int) /* The value is the number of retries already done (0 for first wait) */
		case finished
		
		var isFinished: Bool {
			switch self {
			case .finished: return true
			default:        return false
			}
		}
		
		var isWaitingToRetry: Bool {
			switch self {
			case .waitingToRetry(_): return true
			default:                 return false
			}
		}
		
		var isRunningOrWaitingToRetry: Bool {
			switch self {
			case .running(_):        return true
			case .waitingToRetry(_): return true
			default:                 return false
			}
		}
		
		var numberOfRetries: Int? {
			switch self {
			case .running(let n):        return n
			case .waitingToRetry(let n): return n
			default: return nil
			}
		}
		
	}
	
	public var numberOfRetries: Int? {
		retryStateSemaphore.wait(); defer {retryStateSemaphore.signal()}
		return retryingState.numberOfRetries
	}
	
	deinit {
		if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {os_log("Deiniting retrying operation %{public}@", type: .debug, String(describing: Unmanaged.passUnretained(self).toOpaque()))}
		else                                                          {NSLog("Deiniting retrying operation %@", String(describing: Unmanaged.passUnretained(self).toOpaque()))}
	}
	
	/** `isAsynchronous` **must** be overwritten for RetryingOperations. The
	rationale is: RetryingOperations are _much_ easier than standard Operations
	to create, in particular asynchronous operations. By default an Operation is
	synchronous, which, with no modifications on the isAsynchronous property,
	would make a RetryingOperation synchronous by default too. This is not such a
	good behavior; we prefer forcing subclassers to explicitely say whether
	they're creating a synchronous or an asynchronous operation. */
	open override var isAsynchronous: Bool {
		fatalError("isAsynchronous is abstract on a RetryingOperation")
	}
	
	public final override func start() {
		if !isAsynchronous {super.start()}
		else {
			/* We are in an asynchronous operation, we must start the operation ourselves. */
			retryQueue.async{ self._startBaseOperationOnQueue(isRetry: false) }
		}
	}
	
	/* Note: The synchronous implementation deserves a little more tests.
	 *       Currently it is only very lightly tested with a few unit tests. */
	public final override func main() {
		assert(!isAsynchronous)
		
		var retry = true
		var isRetry = false
		mainLoop: while retry {
			var helpers: [RetryHelper]? = retryQueue.sync {
				_startBaseOperationOnQueue(isRetry: isRetry); assert(!isBaseOperationRunning)
				let ret = syncOperationRetryHelpers; syncOperationRetryHelpers = nil
				if ret != nil {retryingState = .waitingToRetry(nRetries)}
				return ret
			}
			retry = (helpers != nil)
			
			while let currentHelpers = helpers {
				var timeToWait: TimeInterval?
				var filteredHelpers = [RetryHelper]()
				for helper in currentHelpers {
					switch helper {
					case let timerHelper as TimerRetryHelper:
						/* The Timer Retry Helper is handled differently for
						 * optimizations and wait time precision. */
						if let t = timeToWait {timeToWait = min(t, timerHelper.delay)}
						else                  {timeToWait = timerHelper.delay}
						
					default: filteredHelpers.append(helper)
					}
				}
				
				helpers = nil
				
				let startWaitTime = Date()
				repeat {
					guard !isCancelled else {break mainLoop}
					Thread.sleep(forTimeInterval: timeToWait.map{ max(0, min(0.5, $0 + startWaitTime.timeIntervalSinceNow)) } ?? 0.5)
					
					let shouldRefreshHelpers: Bool = retryQueue.sync {
						guard syncRefreshRetryHelpers else {return false}
						helpers = syncOperationRetryHelpers
						syncOperationRetryHelpers = nil
						syncRefreshRetryHelpers = false
						return true
					}
					guard !shouldRefreshHelpers else {break}
				} while timeToWait.map{ -startWaitTime.timeIntervalSinceNow < $0 } ?? true
			}
			isRetry = true
		}
		retryingState = .finished
	}
	
	public final func retryNow() {
		retry(withHelpers: nil)
	}
	
	public final func retry(in delay: TimeInterval) {
		retry(withHelpers: [TimerRetryHelper(retryDelay: delay, retryingOperation: self)])
	}
	
	/**
	- Warning: If you call this method with an empty array of retry helpers, the
	base operation will never be retrying (that is until retry is called again).
	But if you call this method with `nil`, the base operation is retried *now*. */
	public final func retry(withHelpers helpers: [RetryHelper]?) {
		retryQueue.async{ self._unsafeRetry(withHelpers: helpers) }
	}
	
	/* **********************
	   MARK: - For Subclasses
	   ********************** */
	
	/**
   The entry point for subclasses. If your operation is not asynchronous, the
	operation must have finished by the time this method returns
	(`baseOperationEnded()` must have been called).
	
	It is valid to call `baseOperationEnded` from the start operation. (For sync
	operations it is actually required.)
	
	- Note: Do **NOT** call this manually, neither from a subclass or when using
	a retrying operation. I would have liked the method to be protected, but
	protected does not exist in Swift. */
	open func startBaseOperation(isRetry: Bool) {
	}
	
	/**
	The cancellation point for subclasses. **Never** overwrite `cancel()`
	(actually you can't). When this method is called, the `isCancelled` property
	of the operation is guaranteed to be `true`.
	
	Be sure to handle gracefully the cases where you're called here even after
	you've called `baseOperationEnded`. Indeed, this should not happen _in
	general_, but because of race condition, it is _possible_ that it does.
	
	In general you should not have to overwrite this for synchronous operations
	(you should instead check the isCancelled property regularly). The method
	will be called anyways; you can overwrite it even for synchronous operations.
	
	- Note: Do **NOT** call this manually, neither from a subclass or when using
	a retrying operation. I would have liked the method to be protected, but
	protected does not exist in Swift. */
	open func cancelBaseOperation() {
	}
	
	public final func baseOperationEnded() {
		baseOperationEnded(retryHelpers: nil)
	}
	
	public final func baseOperationEnded(needsRetryIn delay: TimeInterval) {
		baseOperationEnded(retryHelpers: [TimerRetryHelper(retryDelay: delay, retryingOperation: self)])
	}
	
	/**
   Subclasses **must** call this method when their base operation ends (or one
	of the derivative above). You can call them from any thread you want.
	
	- Note: Would have liked to be protected, but protected does not exist in
	Swift. */
	public final func baseOperationEnded(retryHelpers: [RetryHelper]?) {
		/* For synchronous operations, the retrying is handled directly in main().
		 * We do NOT dispatch on the retry queue as we should already be on it! */
		guard isAsynchronous else {
			assert(isExecuting && isBaseOperationRunning)
			syncOperationRetryHelpers = retryHelpers
			isBaseOperationRunning = false
			return
		}
		
		retryQueue.async {
			assert(self.isExecuting && self.isBaseOperationRunning)
			self.isBaseOperationRunning = false
			
			guard !self.isCancelled, let retryHelpers = retryHelpers else {
				self.retryingState = .finished
				return
			}
			
			/* We need retrying the base operation. */
			self.retryingState = .waitingToRetry(self.nRetries)
			self.retryHelpers = retryHelpers
		}
	}
	
	/* Since iOS 11, releasing a timer that has never been resumed crash. So we
	 * need to set this entity as a class instead of a struct so we can have a
	 * “hasBeenResumed” var, modified in `setup()` without a “mutating” modifier
	 * on the method… */
	public class TimerRetryHelper : RetryHelper {
		
		public init(retryDelay d: TimeInterval, retryingOperation: RetryingOperation) {
			delay = d
			
			timer = DispatchSource.makeTimerSource(flags: [], queue: retryingOperation.retryQueue)
			timer.setEventHandler{ retryingOperation._unsafeRetry(withHelpers: nil) }
			timer.schedule(deadline: .now() + d, leeway: .milliseconds(250))
		}
		
		deinit {
			timer.setEventHandler(handler: nil)
			/* On iOS 11, releasing a timer that has never been resumed will crash. */
			if #available(iOS 11.0, *), !hasBeenResumed {timer.resume(); timer.cancel()}
		}
		
		public func setup() {
			timer.resume()
			hasBeenResumed = true
		}
		
		public func teardown() {
			timer.cancel()
		}
		
		private var hasBeenResumed = false
		
		private let timer: DispatchSourceTimer
		fileprivate let delay: TimeInterval /* For synchronous operations... */
		
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var nRetries = 0
	
	private var retryHelpers: [RetryHelper]? {
		willSet {retryHelpers?.forEach{ $0.teardown() }}
		didSet  {retryHelpers?.forEach{ $0.setup() }}
	}
	
	private let retryStateSemaphore = DispatchSemaphore(value: 1)
	private let retryQueue = DispatchQueue(label: "Queue for Syncing Retries (for One Retrying Operation)", qos: .utility)
	
	/* Only used for synchronous operations. */
	private var syncRefreshRetryHelpers = false
	private var syncOperationRetryHelpers: [RetryHelper]?
	
	private var retryingState = RetryingOperationState.inited {
		willSet(newState) {
			let newStateExecuting = newState.isRunningOrWaitingToRetry
			let oldStateExecuting = retryingState.isRunningOrWaitingToRetry
			let newStateFinished = newState.isFinished
			let oldStateFinished = retryingState.isFinished
			
			willChangeValue(forKey: "retryingState")
			if newStateExecuting != oldStateExecuting {willChangeValue(forKey: "isExecuting")}
			if newStateFinished  != oldStateFinished  {willChangeValue(forKey: "isFinished")}
			
			retryStateSemaphore.wait()
		}
		didSet(oldState) {
			retryStateSemaphore.signal()
			
			let newStateExecuting = retryingState.isRunningOrWaitingToRetry
			let oldStateExecuting = oldState.isRunningOrWaitingToRetry
			let newStateFinished = retryingState.isFinished
			let oldStateFinished = oldState.isFinished
			
			if newStateFinished  != oldStateFinished  {didChangeValue(forKey: "isFinished")}
			if newStateExecuting != oldStateExecuting {didChangeValue(forKey: "isExecuting")}
			didChangeValue(forKey: "retryingState")
		}
	}
	
	private func _startBaseOperationOnQueue(isRetry: Bool) {
		assert(!isBaseOperationRunning)
		
		guard !isCancelled else {
			retryingState = .finished
			return
		}
		
		if isRetry {nRetries += 1}
		retryingState = .running(nRetries)
		isBaseOperationRunning = true
		
		startBaseOperation(isRetry: isRetry)
	}
	
	private func _unsafeRetry(withHelpers helpers: [RetryHelper]?) {
		guard retryingState.isWaitingToRetry else {
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {os_log("Trying to force retry operation %{public}p which is not waiting to be retried...", self)}
			else                                                          {NSLog("Trying to force retry operation %p which is not waiting to be retried...", self)}
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {os_log("   Don't worry it might be normal (race in retry helpers). Doing nothing. FYI, current status is %{public}@.", String(describing: retryingState))}
			else                                                          {NSLog("   Don't worry it might be normal (race in retry helpers). Doing nothing. FYI, current status is %@.", String(describing: retryingState))}
			return
		}
		
		if isAsynchronous {
			retryHelpers = helpers /* Tears-down previous helpers and setup new ones... */
			if helpers == nil {_startBaseOperationOnQueue(isRetry: true)} /* ...but does not start the base operation if helpers is nil. */
		} else {
			syncRefreshRetryHelpers = true
			syncOperationRetryHelpers = helpers
		}
	}
	
	public final override func cancel() {
		super.cancel()
		guard isAsynchronous else {cancelBaseOperation(); return}
		
		retryQueue.async {
			if self.retryHelpers != nil {
				assert(self.retryingState.isWaitingToRetry)
				
				/* Tears-down the retry helpers. */
				self.retryHelpers = nil
				
				/* If we're waiting for a retry, the base operation will never
				 * notify us we're over, it's up to us to say the operation has
				 * ended. */
				self.retryingState = .finished
			} else {
				self.cancelBaseOperation()
			}
		}
	}
	
	private var isBaseOperationRunning = false
	
	public final override var isExecuting: Bool {
		retryStateSemaphore.wait(); defer {retryStateSemaphore.signal()}
		return retryingState.isRunningOrWaitingToRetry
	}
	
	public final override var isFinished: Bool {
		retryStateSemaphore.wait(); defer {retryStateSemaphore.signal()}
		return retryingState.isFinished
	}
	
}

public protocol RetryHelper {
	
	func setup()
	func teardown()
	
}
