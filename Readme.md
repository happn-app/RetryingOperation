# Retrying Operations
![Platforms](https://img.shields.io/badge/platform-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20Linux-lightgrey.svg?style=flat) [![SPM compatible](https://img.shields.io/badge/SPM-compatible-E05C43.svg?style=flat)](https://swift.org/package-manager/) [![License](https://img.shields.io/github/license/happn-tech/RetryingOperation.svg)](License.txt) [![happn](https://img.shields.io/badge/from-happn-0087B4.svg?style=flat)](https://happn.com)

## What is it?
An abstract class for retrying operations. The idea is to provide a clean and
easy way to create retrying operations. For instance, if you make an operation
to fetch some network resources, the operation might fail because there is no
Internet right now. However, Internet might be back soon! Instead of bothering
your user by telling him there’s no net and he should retry, you might want to
wait a few seconds and retry the request(s).

The retrying operation class gives you a way to easily handle the retrying
process.

_Note_: Cancelled operations are not retried.

## How to use it?
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

## What about operations I don’t own?
Use case: I'm using a framework which provide nice operations. I would want to
make these operations retryable, but I cannot make them inherit from
`RetryingOperation` as I do not own them. What can I do?

A solution is to use `RetryableOperationWrapper`. See the doc of this class
for more information.

## Credits
This project was originally created by [François Lamboley](https://github.com/Frizlab) while working at [happn](https://happn.com).
