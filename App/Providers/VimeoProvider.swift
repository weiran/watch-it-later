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
    
    func videoStream(preferredFormatType: VideoFormatType? = nil) -> Promise<VideoStream> {
        let (promise, seal) = Promise<VideoStream>.pending()
        
        YTVimeoExtractor.shared().fetchVideo(withVimeoURL: url.absoluteString, withReferer: nil) { video, error in
            if let video = video {
                /// TODO we're cheating here by guessing the top quality video is 1080p
                /// and going for the top quality no matter what the setting is
                /// we need to map between selected max format and Vimeo format types to
                /// select the right one
                let streamURL = video.highestQualityStreamURL()
                let duration = Double(video.duration)
                let thumbnailURL = video.thumbnailURLs?[NSNumber(value: YTVimeoVideoThumbnailQuality.HD.rawValue)] ??
                    video.thumbnailURLs?[NSNumber(value: YTVimeoVideoThumbnailQuality.medium.rawValue)] ??
                    video.thumbnailURLs?[NSNumber(value: YTVimeoVideoThumbnailQuality.small.rawValue)]
                let videoStream = VideoStream(
                    videoURL: streamURL,
                    audioURL: nil,
                    duration: duration,
                    videoFormatType: .video1080p,
                    thumbnailURL: thumbnailURL
                )
                seal.fulfill(videoStream)
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(VideoError.NoStreamURLFound)
            }
        }
        
        return promise
    }
}
