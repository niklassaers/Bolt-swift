import PackageDescription

let package = Package(
    name: "bolt-swift",
	dependencies: [
	        .Package(url: "https://github.com/niklassaers/PackStream-swift.git",
	                 majorVersion: 0),
	    ]
)
