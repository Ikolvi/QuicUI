#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint quicui.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'quicui'
  s.version          = '2.0.3'
  s.summary          = 'QuicUI Code Push Client for iOS'
  s.description      = <<-DESC
QuicUI Code Push Client enables over-the-air updates for Flutter apps built with QuicUI SDK.
                       DESC
  s.homepage         = 'https://quicui.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'QuicUI' => 'info@quicui.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,swift}'
  s.dependency 'Flutter'
  s.platform = :ios, '13.4'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
