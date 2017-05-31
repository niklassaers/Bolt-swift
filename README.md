# Bolt-swift
The Bolt network protocol is a network protocol designed for high-performance access to graph databases. Bolt is a connection-oriented protocol, using a compact binary encoding over TCP or web sockets for higher throughput and lower latency.

The reference implementation can be found [here][https://github.com/neo4j-contrib/boltkit]. This codebase is the Swift implementation, and is used by Theo, the Swift Neo4j driver.

## Connection
The implementation supports both SSL-encrypted and plain-text connections. If there is no certificate and key provided with the SSL configuration, Bolt-swift will attempt to generate it.

## Tests

Note, tests are destructive to the data in the database under test, so run them on a database created especially for running the tests

## Getting started

To use directly with Xcode, type "swift package generate-xcodeproj"


### Swift Package Manager
Add the following to your dependencies array in Package.swift:
```swift
.Package(url: "https://github.com/niklassaers/bolt-swift.git",
 majorVersion: 0),
```
and you can now do a
```bash
swift build
```

### CocoaPods
Add the 
```ruby
pod "BoltProtocol"
```
to your Podfile, and you can now do
```bash
pod install
```
to have Bolt included in your Xcode project via CocoaPods

### Carthage
Put 
```ogdl
github "niklassaers/bolt-swift"
```
in your Cartfile. If this is your entire Cartfile, do
```bash
carthage bootstrap
```
If you have already done that, do
```bash
carthage update
```
instead.

Then do 
```bash
cd Carthage/Checkouts/bolt-swift
swift package generate-xcodeproj
cd -
```

And Carthage is now set up. You can now do
```bash
carthage build --platform Mac
```
and you should find a build for macOS. If you want to build for iOS, before generating the Xcode project, remove the ShellOut dependency from Package.swift, and then use --platoform iOS instead.
tvOS and watchOS builds with Carthage are currently unavailable.
