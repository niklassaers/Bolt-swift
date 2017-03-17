import PackageDescription

let package = Package(
    name: "Bolt",
	dependencies: [
	        .Package(url: "https://github.com/niklassaers/PackStream-swift.git",
	                 majorVersion: 0),
		.Package(url: "https://github.com/IBM-Swift/BlueSSLService.git", majorVersion: 0),
	    ]
)
