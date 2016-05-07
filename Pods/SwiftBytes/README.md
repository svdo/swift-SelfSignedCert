Swift Bytes [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
===========

This library contains a collection of helper methods for byte manipulation in Swift.

If you're like me, and can never remember whether you should double right-shift or tripple left-shift to get to the bits you want, then this library might be of some use to you.

Example
-------

	// Let's say we have an interesting 64 bit number:
	let largeNumber: UInt64 = 0xF00FA00AB00BC00C

	// Extracting the fifth byte, the hard way:
	let fifthByte = UInt8((largeNumber >> 24) & 0xFF)

	// Extracting the fifth byte using this libary:
	let fifthByte = bytes(largeNumber)[4]

All available byte manipulation methods can be found in the `Bytes.swift` file. The `BytesTests.swift` file contains examples of their use.

Installation
------------

You can use [CocoaPods] to add this library to your project. Use the following in your Podfile:

	pod 'SwiftBytes'

After adding this library to your project, you can import it in your swift files:

	import SwiftBytes

[CocoaPods]: http://cocoapods.org
