// This file is used to prevent XCode instantiating AppDelegate which distorts the runtime and code coverage results
import UIKit

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSClassFromString("XCTestCase") == nil ? NSStringFromClass(AppDelegate.self) : nil
)
