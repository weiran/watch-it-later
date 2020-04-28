platform :tvos, '12.0'
use_frameworks!
inhibit_all_warnings!

target 'WatchItLater' do

  # Pods for Watch It Later
  pod 'XCDYouTubeKit'
  pod 'YTVimeoExtractor', :git => 'https://github.com/lilfaf/YTVimeoExtractor', :commit => '57bf479e860abd7dcd5fcbc520062cea3c7b5587'
  pod 'Locksmith'
  pod 'Kingfisher'
  pod 'PromiseKit/CorePromise'
  pod 'RealmSwift'
  pod 'TVVLCKit'
  pod 'TVVLCPlayer', :git => 'https://github.com/weiran/TVVLCPlayer', :branch => 'kodlian_master'
# pod 'TVVLCPlayer', :path => "../../Forks/TVVLCPlayer/TVVLCPlayer.podspec"
  pod 'SwiftyUserDefaults'
  pod 'Swinject'
  pod 'SwinjectStoryboard'
end

# workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
pre_install do |installer|
  Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end
