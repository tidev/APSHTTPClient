#
# Be sure to run `pod lib lint APSHTTPClient.podspec' to ensure this
# is a valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'APSHTTPClient'
  s.version          = '1.1.0'
  s.summary          = 'An experimental replacement for ASIHTTPRequest use cases in Titanium.'
  s.description      = <<-DESC
                       This is an experimental iOS library to replace
                       ASIHTTPRequest use cases in Titanium. It may
                       find use in Titanium and the Appcelerator
                       Native SDK for iOS.
                       DESC
  s.homepage         = 'https://github.com/appcelerator/APSHTTPClient/'
  s.license          = 'Apache License, Version 2.0'
  s.author           = {
    'Pedro Enrique' => 'penrique@appcelerator.com',
    'Sabil Rahim'   =>  'srahim@appcelerator.com',
    'Vishal Duggal' => 'vduggal@appcelerator.com'
  }
  s.source           = { :git => 'https://github.com/appcelerator/APSHTTPClient.git', :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '6.1'
  s.requires_arc = true

  s.source_files = 'APSHTTPClient'

  s.ios.exclude_files = 'APSHTTPClient/osx'
  s.osx.exclude_files = 'APSHTTPClient/ios'
  s.public_header_files = 'APSHTTPClient/**/*.h'
  s.ios.frameworks = 'MobileCoreServices', 'SystemConfiguration'
  
  # s.dependency 'JSONKit', '~> 1.4'
end

