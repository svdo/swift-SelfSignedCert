# SelfSignedCert

![Swift Version 5](https://img.shields.io/badge/Swift-v5-yellow.svg)
[![CocoaPods Version Badge](https://img.shields.io/cocoapods/v/SelfSignedCert.svg)](https://cocoapods.org/pods/SelfSignedCert)
[![License Badge](https://img.shields.io/cocoapods/l/SelfSignedCert.svg)](LICENSE.txt)
![Supported Platforms Badge](https://img.shields.io/cocoapods/p/SelfSignedCert.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

This project provides a Swift framework that allows you to create self-signed
certificates on iOS, using Swift. Unfortunately, Apple does not provide this
functionality in their security frameworks. Another way of doing it is using
OpenSSL, but (especially when using Swift) that is downright horrible.

The code in this library is a (partial) port of
[MYCrypto](https://github.com/snej/MYCrypto). That project contains unmaintained
Objective-C code, which was difficult to use as a CocoaPod and especially also
when using Swift. So I took that part that I needed and implemented that in
Swift.

Please note that I'm not a security expert. This framework has not been reviewed
by a security expert. Until it has, please use with caution! And in any case
(reviewed or not), using it is always at your own risk of course.

If you are a security expert and you want to review this framework, please
contact me.
