#
# Be sure to run `pod lib lint LogTape.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LogTape+AFNetworking'
  s.version          = '0.1.0'
  s.summary          = 'A short description of LogTape.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/LogTape/LogTape-iOS'
  s.license          = { :type => 'Custom', :text : "Copyright 2017 Tightloop AB. See https://www.logtape.io/license" }
  s.author           = { 'Dan Nilsson' => 'dan@binarypeak.se' }
  s.source           = { :git => 'https://github.com/LogTape/LogTape-iOS.git' }

  s.ios.deployment_target = '9.0'

  s.source_files = 'LogTape+AFNetworking/Classes/**/*'
  s.dependency 'LogTape'
  s.dependency 'AFNetworking'
end
