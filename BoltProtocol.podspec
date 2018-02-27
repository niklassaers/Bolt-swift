Pod::Spec.new do |s|

  s.name         = "BoltProtocol"
  s.module_name  = 'Bolt'
  s.version      = "1.0.1"
  s.summary      = "Bolt protocol implementation in Swift"

  s.description  = <<-DESC
The Bolt network protocol is a highly efficient, lightweight client-server protocol designed for database applications.

The reference implementation can be found [here][https://github.com/neo4j-contrib/boltkit]. This is the Swift implementation, and is used by Theo, the Swift Neo4j driver.
DESC

  s.homepage     = "https://github.com/Neo4j-Swift/Bolt-swift"

  s.authors            = { "Niklas Saers" => "niklas@saers.com" }
  s.social_media_url   = "http://twitter.com/niklassaers"

  s.license      = { :type => "BSD", :file => "LICENSE" }

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.11"
  s.tvos.deployment_target = "10.0"

  s.source       = { :git => "https://github.com/Neo4j-Swift/bolt-swift.git", :tag => "#{s.version}" }
  s.source_files  = "Sources"

  s.dependency 'PackStream', '~> 1.0.1'
  s.dependency 'BlueSocket', '~> 0.12.94'
  s.dependency 'BlueSSLService', '~> 0.12.84'
  
end
