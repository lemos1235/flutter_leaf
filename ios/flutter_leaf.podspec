#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_leaf.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_leaf'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter vpn plugin based on leaf.'
  s.description      = <<-DESC
A new flutter vpn plugin based on leaf.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', 'Templates/**/*'
  s.resources = ['Templates/Info.plist', 'Templates/VPNExtension.entitlements']
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'SWIFT_OBJC_BRIDGING_HEADER' => '${PODS_TARGET_SRCROOT}/Classes/Flutter-Leaf-Bridging-Header.h'
  }
  s.swift_version = '5.0'

  # 添加 NetworkExtension 框架依赖
  s.framework = 'NetworkExtension'
  
  # 添加静态库作为资源
  s.vendored_libraries = 'Classes/libleaf/libleaf.a'
  
  # 添加头文件搜索路径
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '${PODS_TARGET_SRCROOT}/Classes/libleaf' }

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_leaf_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
