Pod::Spec.new do |s|

  s.name         = "Aerial"
  s.version      = "0.0.1"
  s.summary      = "iOS client library for Aerial Remote Debugging Tool"
  s.description  = <<-DESC
  Client library for Aerial Remote Debugging Tool. 
  Embed it in your project to be able to monitor logs and container in Aerial app.
                   DESC

  s.homepage     = "https://github.com/yariksmirnov/aerial"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Yaroslav Smirnov" => "yarikbonch@gmail.com" }
  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/yariksmirnov/aerial.git", :tag => "#{s.version}" }

  s.source_files  = "shared/*.{h,m,swift}", "ios/*.swift", "ios/loggers/CorkDestination.swift"
  s.frameworks = "MultipeerConnectivity"
  s.requires_arc = true

  s.dependency "ObjectMapper"
  s.dependency "XCGLogger"
  s.dependency "Dollar"

end
