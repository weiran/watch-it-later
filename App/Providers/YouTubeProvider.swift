//
//  YouTubeProvider.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit

import PromiseKit
import XCDYouTubeKit

class YouTubeProvider: VideoProviderProtocol {
    var url: URL
    var identifier: String = ""
    
    required init(_ url: String) throws {
        self.url = URL(string: url)!
        self.identifier = try parseYoutubeIdentifier(url)
    }
    
    func videoStream() -> Promise<VideoStream> {
        return Promise { fulfill, reject in
            XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { video, error in
                if let streamURLs = video?.streamURLs as? Dictionary<Int, URL>,
                    let highestQualityStream = YouTubeProvider.getHighestQualityFormatType(streams: streamURLs),
                    let videoStream = YouTubeProvider.getVideoStream(streams: streamURLs, for: highestQualityStream) {
                    fulfill(videoStream)
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
            XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { video, error in
                // TODO: adding 'sd' or 'hq' to the beginning of the filename for the thumbnail often gives higher quality thumbnails
                if let video = video, let thumbnailURL = video.largeThumbnailURL ?? video.mediumThumbnailURL ?? video.smallThumbnailURL {
                    fulfill(thumbnailURL)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(VideoError.NoThumbnailURLFound)
                }
            }
        }
    }
    
    func duration() -> Promise<Double> {
        return Promise { fulfill, reject in
            XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { video, error in
                if let video = video {
                    fulfill(Double(video.duration))
                } else if let error = error {
                    reject(error)
                } else {
                    reject(VideoError.InvalidURL)
                }
            }
        }
    }
    
    fileprivate func parseYoutubeIdentifier(_ url: String) throws -> String {
        do {
            let identifierRegex = try NSRegularExpression(pattern: "(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)")
            let results = identifierRegex.matches(in: url, range: NSRange(location: 0, length: url.count))
            if results.count > 0 {
                let urlNSString = url as NSString
                return urlNSString.substring(with: results.first!.range)
            } else {
                throw VideoError.InvalidURL
            }
        } catch _ {
            throw VideoError.InvalidURL
        }
    }
    
    fileprivate static func getHighestQualityFormatType(streams: Dictionary<Int, URL>, highestQuality: YouTubeFormatType = .video1080p60) -> YouTubeFormatType? {
        let qualityOrder = [YouTubeFormatType.video2160p60,
                            YouTubeFormatType.video2160p,
                            YouTubeFormatType.video1440p60,
                            YouTubeFormatType.video1440p,
                            YouTubeFormatType.video1080p60,
                            YouTubeFormatType.video1080p,
                            YouTubeFormatType.video720p60,
                            YouTubeFormatType.video720p,
                            YouTubeFormatType.video480p,
                            YouTubeFormatType.video360p
                            ]
        
        guard let startIndex = qualityOrder.index(of: highestQuality) else { return nil }
        
        for i in startIndex..<qualityOrder.count {
            let qualityType = qualityOrder[i]
            let (videoTypeId, _) = qualityType.typeIdentifiers()
            if let _ = streams[videoTypeId] {
                return qualityType
            }
        }
        
        return nil
    }
    
    fileprivate static func getVideoStream(streams: Dictionary<Int, URL>, for quality: YouTubeFormatType) -> VideoStream? {
        let (videoTypeId, audioTypeId) = quality.typeIdentifiers()
        guard let videoURL = streams[videoTypeId] else { return nil }
        var audioURL: URL?
        if let audioTypeId = audioTypeId {
            guard let unoptionalAudioURL = streams[audioTypeId] else { return nil }
            audioURL = unoptionalAudioURL
        }
        
        return VideoStream(videoURL: videoURL, audioURL: audioURL)
    }
}
