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
                /// TODO we're cheating here by guessing the top quality video is 1080p
                /// and going for the top quality no matter what the setting is
                /// we need to map between selected max format and Vimeo format types to
                /// select the right one
                seal.fulfill(VideoStream(videoURL: streamURL, audioURL: nil, videoFormatType: .video1080p))
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
