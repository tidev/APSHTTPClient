#
# Be sure to run `pod lib lint APSHTTPClient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'APSHTTPClient'
  s.version          = '0.0.1'
  s.summary          = 'Base HTTP Client used by Titanium SDK.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Base HTTP Client used by Titanium SDK. Used by Analytics, and the SDK for any http connections.
                       DESC

  s.homepage         = 'https://github.com/appcelerator/APSHTTPClient'
  s.license          = { :type => 'Apache2', :file => 'LICENSE' }
  s.author           = { 'sgtcoolguy' => 'chris.a.williams@gmail.com' }
  s.source           = { :git => 'https://github.com/sgtcoolguy/APSHTTPClient.git', :branch => 'cocoapods' }

  s.ios.deployment_target = '8.0'

  s.source_files = 'APSHTTPClient/Classes/**/*'

  s.frameworks = 'CoreServices'
  # s.vendored_frameworks = 'APSHTTPClient.xcframework'
end
