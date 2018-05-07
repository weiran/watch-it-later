# Watch It Later

[![Build Status](https://travis-ci.org/weiran/watch-it-later.svg?branch=master)](https://travis-ci.org/weiran/watch-it-later)

![Logo][logo]

[logo]: http://i.imgur.com/SyC0DMZ.png

Watch It Later is a native Apple TV app for watching YouTube and Vimeo videos saved to your Instapaper account.

## Features

* HD playback of YouTube and Vimeo videos saved on Instapaper
* Archiving videos in app

![Screenshots][1]

[1]: https://i.imgur.com/78SPj4X.jpg

## Open Source

Watch It Later is open source and licenced under the MIT licence.

[![Download in App Store][3]][2]

[2]: https://itunes.apple.com/us/app/watch-it-later/id1191095941?ls=1&mt=8&at=11l4G8&ct=github
[3]: http://i.imgur.com/oRdf2WM.png

## Links

* You can follow [Watch It Later's progress on my blog](http://weiran.co/).
* You can also get in touch via Twitter: [@weiran](https://twitter.com/weiran).

## How to build

1. Enter your Instapaper OAuth consumer key and secret in `App\Supporting Files\InstapaperConfiguration.defaults.plist`.
2. Rename `InstapaperConfiguration.defaults.plist` to `InstapaperConfiguration.plist`.
3. Install [cocoapods](http://cocoapods.org/), you can use RubyGems: `gem install cocoapods`.
4. Install pods, in the project root folder, run `pod install`.
5. Open the workspace file (`WatchItLater.xcworkspace`) in Xcode 8 or later, and build.

## About

Watch It Later is an open source project by [Weiran Zhang](http://weiran.co) licensed under the [MIT license](http://opensource.org/licenses/MIT).
