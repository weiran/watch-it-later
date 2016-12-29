//
//  VimeoProvider.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import PromiseKit
import YTVimeoExtractor

class VimeoProvider: VideoProviderProtocol {
    
    var url: URL
    
    required init(_ url: String) throws {
        self.url = URL(string: url)!
    }
    
    func streamURL() -> Promise<URL> {
        return Promise { fulfill, reject in
            YTVimeoExtractor.shared().fetchVideo(withVimeoURL: url.absoluteString, withReferer: nil) { video, error in
                if let streamURL = video?.highestQualityStreamURL() {
                    fulfill(streamURL)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(VideoError.NoStreamURLFound)
                }
            }
        }
    }
    
    func thumbnailURL() -> Promise<URL> {
        return Promise { fulfill, reject in
            YTVimeoExtractor.shared().fetchVideo(withVimeoURL: url.absoluteString, withReferer: nil) { video, error in
                if let thumbnailURLs = video?.thumbnailURLs,
                    let thumbnailURL = thumbnailURLs[NSNumber(value: YTVimeoVideoThumbnailQuality.HD.rawValue)] ??
                        thumbnailURLs[NSNumber(value: YTVimeoVideoThumbnailQuality.medium.rawValue)] ??
                        thumbnailURLs[NSNumber(value: YTVimeoVideoThumbnailQuality.small.rawValue)] {
                    fulfill(thumbnailURL)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(VideoError.NoThumbnailURLFound)
                }
            }
        }
    }
    
    func description() -> Promise<String> {
        // figure out a way to get a Vimeo description
        return Promise { fulfill, reject in
            fulfill("")
        }
    }
    
}
