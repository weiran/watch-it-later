platform :tvos, '12.0'
use_frameworks!
inhibit_all_warnings!

target 'WatchItLater' do

  # Pods for Watch It Later
  pod 'XCDYouTubeKit'
  pod 'YTVimeoExtractor', :git => 'https://github.com/lilfaf/YTVimeoExtractor', :commit => '57bf479e860abd7dcd5fcbc520062cea3c7b5587'
  pod 'Locksmith'
  pod 'AsyncImageView'
  pod 'PromiseKit', '~> 4.x'
  pod 'RealmSwift'
  pod 'TVVLCKit'
  pod 'TVVLCPlayer', :git => 'https://github.com/weiran/TVVLCPlayer', :commit => 'a924aea2f0e9984e5853b3eb5f2efaaf5a35a5bc'
  pod 'SwiftyUserDefaults'
  pod 'Swinject'
  pod 'SwinjectStoryboard'
end

# This currently doesn't work in cocoapods 1.4.0, need to manually edit the Pod settings after
post_install do |installer|
    installer.pods_project.targets.each do |target|
        if ['PromiseKit', 'SwinjectStoryboard'].include? target.name
          target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.0'
          end
        end
        if target.name == 'TVVLCPlayer' or target.name == 'TVVLCPlayer-TVVLCPlayer'
          target.build_configurations.each do |config|
            config.build_settings.delete('DEFINES_MODULE')
          end
        end
    end
end
