//
//  VimeoProvider.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import PromiseKit
import YTVimeoExtractor

class VimeoProvider: VideoProviderProtocol {
    var url: URL
    
    required init(_ url: String) throws {
        self.url = URL(string: url)!
    }
    
    func videoStream(preferredFormatType: VideoFormatType?) -> Promise<VideoStream> {
        let (promise, seal) = Promise<VideoStream>.pending()
        
        YTVimeoExtractor.shared().fetchVideo(withVimeoURL: url.absoluteString, withReferer: nil) { video, error in
            if let streamURL = video?.highestQualityStreamURL() {
                seal.fulfill(VideoStream(videoURL: streamURL, audioURL: nil))
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(VideoError.NoStreamURLFound)
            }
        }
        
        return promise
    }
    
    func thumbnailURL() -> Promise<URL> {
        let (promise, seal) = Promise<URL>.pending()
        
        YTVimeoExtractor.shared().fetchVideo(withVimeoURL: url.absoluteString, withReferer: nil) { video, error in
            if let thumbnailURLs = video?.thumbnailURLs,
                let thumbnailURL = thumbnailURLs[NSNumber(value: YTVimeoVideoThumbnailQuality.HD.rawValue)] ??
                    thumbnailURLs[NSNumber(value: YTVimeoVideoThumbnailQuality.medium.rawValue)] ??
                    thumbnailURLs[NSNumber(value: YTVimeoVideoThumbnailQuality.small.rawValue)] {
                seal.fulfill(thumbnailURL)
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(VideoError.NoThumbnailURLFound)
            }
        }
        
        return promise
    }
    
    func duration() -> Promise<Double> {
        let (promise, seal) = Promise<Double>.pending()
        
        YTVimeoExtractor.shared().fetchVideo(withVimeoURL: url.absoluteString, withReferer: nil) { video, error in
            if let video = video {
                seal.fulfill(video.duration)
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(VideoError.InvalidURL)
            }
        }
        
        return promise
    }
}
