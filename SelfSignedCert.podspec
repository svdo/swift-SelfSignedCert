Pod::Spec.new do |s|
  s.name         = "SelfSignedCert"
  s.version      = "3.0.1"
  s.summary      = "A framework for iOS that allows creating self-signed certificates, implemented in Swift."
  s.description  = <<-DESC
                   On iOS, you cannot simply create self-signed certificates.
                   You could try and pull out OpenSSL, but that will turn into
                   a nightmare very quickly. This library provides functionality
                   to create self-signed certificates in Swift. DISCLAIMER: I
                   am no security expert. This library has not been audited by
                   one. I just ported a part of another library, copying many
                   of the unit tests in there, but I don't know if they were all
                   correct... Use at your own risk! By the way: if you are a
                   security expert and want to audit this library, that would
                   earn you LOTS and LOTS of gratitude! Please contact me.
                   DESC

  s.homepage     = "https://github.com/svdo/swift-SelfSignedCert"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author             = { "Stefan van den Oord" => "soord@mac.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/svdo/swift-SelfSignedCert.git", :tag => "#{s.version}" }
  s.source_files  = "SelfSignedCert/**/*.swift"
  s.dependency "SecurityExtensions", "~> 4.0"
  s.swift_version = '5'
end
