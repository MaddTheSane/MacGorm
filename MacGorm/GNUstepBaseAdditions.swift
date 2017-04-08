//
//  GNUstepBaseAdditions.swift
//  MacGorm
//
//  Created by C.W. Betts on 4/7/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Foundation
import GNUstepBase.NSDebug_GNUstepBase



///`NSDebugLLog()` is the basic debug logging macro used to display
///log messages using `NSLog()`, if debug logging was enabled at compile
///time and the appropriate logging level was set at runtime.
///
///Debug logging which can be enabled/disabled by defining *GSDIAGNOSE*
///when compiling and also setting values in the mutable set which
///is set up by `NSProcessInfo`. *GSDIAGNOSE* is defined automatically
///unless *diagnose=no* is specified in the make arguments.
///
///`NSProcess` initialises a set of strings that are the names of active
///debug levels using the '--GNU-Debug=...' command line argument.
///Each command-line argument of that form is removed from
///`NSProcessInfo`'s list of arguments and the variable part
///(...) is added to the set.
///This means that as far as the program proper is concerned, it is
///running with the same arguments as if debugging had not been enabled.
///
///For instance, to debug the `NSBundle` class, run your program with
///'--GNU-Debug=NSBundle'
///You can of course supply multiple '--GNU-Debug=...' arguments to
///output debug information on more than one thing.
///
///`NSUserDefaults` also adds debug levels from the array given by the
///GNU-Debug key ... but these values will not take effect until the
///`+standardUserDefaults` method is called ... so they are useless for
///debugging `NSUserDefaults` itself or for debugging any code executed
///before the defaults system is used.
///
///To embed debug logging in your code you use the `NSDebugLLog()` or
///`NSDebugLog()` macro.  `NSDebugLog()` is just `NSDebugLLog()` with the debug
///level set to `"dflt"`.  So, to activate debug statements that use
///NSDebugLog(), you supply the '--GNU-Debug=dflt' argument to your program.
///
///You can also change the active debug levels under your programs control -
///`NSProcessInfo` has a `[-debugSet]` method that returns the mutable set that
///contains the active debug levels - your program can modify this set.
///
///Two debug levels have a special effect - 'dflt' is the level used for
///debug logs statements where no debug level is specified, and 'NoWarn'
///is used to *disable* warning messages.
///
///As a convenience, there are four more logging macros you can use -
///`NSDebugFLog()`, `NSDebugFLLog()`, `NSDebugMLog()` and `NSDebugMLLog()`.
///These are the same as the other macros, but are specifically for use in
///either functions or methods and prepend information about the file, line
///and either function or class/method in which the message was generated.
/// - parameter level: the debug level to check for.
/// - parameter format: The `NSString`-like format to print to console.
func NSDebugLLog(level: String, _ format: String, args: CVarArg...) {
	if GSDebugSet(level) {
		withVaList(args, { (val) -> Void in
			NSLogv(format, val)
		})
	}
}


/// This macro is a shorthand for `NSDebugLLog()` using then default debug
/// level ... `"dflt"`
///
/// - parameter format: The `NSString`-like format to print to console.
func NSDebugLog(_ format: String, args: CVarArg...) {
	NSDebugLLog(level: "dflt", format, args: args)
}

/// This function is like `NSDebugLLog()` but includes the name and location
/// of the function in which the macro is used as part of the log output.
///
/// - parameter level: the debug level to check for.
/// - parameter format: The `NSString`-like format to print to console.
func NSDebugFLLog(level: String, file: String = #file, line: Int32 = #line, function: String = #function, _ format: String, args: CVarArg...) {
	if GSDebugSet(level) {
		
		let a = withVaList(args, { (lists) -> String in
			return NSString(format: format, arguments: lists) as String
			//return String(format: format, arguments: lists)
		})
		
		let s = GSDebugFunctionMsg(function, file, line, a) ?? "<nil>"
		NSLog("%@", s)
	}
}

/// This macro is a shorthand for NSDebugFLLog() using then default debug
/// level ... `"dflt"`
///
/// - parameter format: The `NSString`-like format to print to console.
func NSDebugFLog(file: String = #file, line: Int32 = #line, function: String = #function, _ format: String, args: CVarArg...) {
	NSDebugFLLog(level: "dflt", file: file, line: line, function: function, format, args: args)
}

/*
/**
* This macro is like NSDebugLLog() but includes the name and location
* of the <em>method</em> in which the macro is used as part of the log output.
*/
func NSDebugMLLog(file: String = #file, line: Int32 = #line, function: Selector = #function, _ level: String, _ format: String, args: [CVarArg]) {
	if GSDebugSet("dflt") {
		let a = withVaList(args, { (lists) -> String in
			return NSString(format: format, arguments: lists) as String
		})
		let s = GSDebugMethodMsg(nil, function, file, line, a) ?? "<nil>"
		NSLog("%@", s)
	}
}

/**
* This macro is a shorthand for NSDebugMLLog() using then default debug
* level ... 'dflt'
*/
#define NSDebugMLog(format, args...) \
do { if (GSDebugSet(@"dflt") == YES) { \
NSString *s = GSDebugMethodMsg( \
self, _cmd, __FILE__, __LINE__, \
[NSString stringWithFormat: format, ##args]); \
NSLog(@"%@", s); }} while (0)
*/

/*
/**
* This macro saves the name and location of the function in
* which the macro is used, along with a short string msg as
* the tag associated with a recorded object.
*/
func NSDebugFRLog(_ object: Any, msg: String, file: String = #file, line: Int32 = #line, function: String = #function) {
	let tag = GSDebugFunctionMsg(function, file, line, msg)!
	GSDebugAllocationTagRecordedObject(object, tag)
}

/**
* This macro saves the name and location of the method in
* which the macro is used, along with a short string msg as
* the tag associated with a recorded object.
*/
#define NSDebugMRLog(object, msg) \
do { \
NSString *tag = GSDebugMethodMsg( \
self, _cmd, __FILE__, __LINE__, msg); \
GSDebugAllocationTagRecordedObject(object, tag); } while (0)
*/
