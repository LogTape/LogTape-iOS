#
# Be sure to run `pod lib lint LogTape.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LogTape'
  s.version          = '0.1.7'
  s.summary          = 'LogTape allows you to upload application logs, screenshots and videos that you can review later at https://www.logtape.io'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
LogTape makes it easier for you diagnose what went wrong in your app. Shake your device when something looks odd and inspect network calls, screenshot and recorded videos at a later date.

Makes it a lot easier to deal panicked testers that want to show you a rare bug that's super tough to reproduce. You can quickly deduce if it's backend related without having to plug in a device, log in with the same user, try to reproduce the same flow and so on. You won't have to interrupt your current flow to investigate.

The logs are stored on https://www.logtape.io in precise detail that's easy to follow. Inspect headers, response times, payloads, status codes and so on. 

Once your team integrates the tool into the day-to-day workflow it's great to include a link to a log from a JIRA issue and so on. 
                       DESC

  s.homepage         = 'https://github.com/LogTape/LogTape-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Custom', :text => "Copyright 2017 Tightloop AB. See https://www.logtape.io/license" }
  s.author           = { 'Dan Nilsson' => 'dan@binarypeak.se' }
  s.source           = { :git => 'https://github.com/LogTape/LogTape-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'LogTape/Classes/**/*'
  
  s.resource_bundles = {
    'LogTape' => ['LogTape/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
