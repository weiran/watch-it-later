//
//  VimeoProvider.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import PromiseKit
import Foundation

class VimeoProvider: VideoProviderProtocol {
    var url: URL
    
    required init(_ url: String) throws {
        self.url = URL(string: url)!
    }
    
    func videoStream() -> Promise<VideoStream> {
        let (promise, seal) = Promise<VideoStream>.pending()

        HCVimeoVideoExtractor.fetchVideoURLFrom(url: self.url) { video, error in
            if let video = video {
                let videoStream = VideoStream(
                    videoURL: video.videoURL[.quality1080p]!,
                    audioURL: nil,
                    duration: Double(video.duration),
                    videoFormatType: VideoFormatType.video1080p,
                    thumbnailURL: video.thumbnailURL[.quality1280]
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
