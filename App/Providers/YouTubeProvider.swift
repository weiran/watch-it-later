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
    
    func videoStream(preferredFormatType: VideoFormatType?) -> Promise<VideoStream> {
        let (promise, seal) = Promise<VideoStream>.pending()

        XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { video, error in
            if let streamURLs = video?.streamURLs as? Dictionary<Int, URL>,
                let highestQualityStream = YouTubeProvider.getHighestQualityFormatType(streams: streamURLs, highestQuality: preferredFormatType ?? .video1080p60),
                let videoStream = YouTubeProvider.getVideoStream(streams: streamURLs, for: highestQualityStream) {
                seal.fulfill(videoStream)
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
        
        let urlString = "https://i.ytimg.com/vi/\(identifier)/maxresdefault.jpg"
        if let url = URL(string: urlString) {
            seal.fulfill(url)
        } else {
            seal.reject(VideoError.NoThumbnailURLFound)
        }
        
        return promise
    }
    
    func duration() -> Promise<Double> {
        let (promise, seal) = Promise<Double>.pending()
        
        XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { video, error in
            if let video = video {
                seal.fulfill(Double(video.duration))
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(VideoError.InvalidURL)
            }
        }
        
        return promise
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
    
    fileprivate static func getHighestQualityFormatType(streams: Dictionary<Int, URL>, highestQuality: VideoFormatType = .video2160p60) -> VideoFormatType? {
        let qualityOrder = [VideoFormatType.video2160p60,
                            VideoFormatType.video2160p,
                            VideoFormatType.video1440p60,
                            VideoFormatType.video1440p,
                            VideoFormatType.video1080p60,
                            VideoFormatType.video1080p,
                            VideoFormatType.video720p60,
                            VideoFormatType.video720p,
                            VideoFormatType.video480p,
                            VideoFormatType.video360p
                            ]
        
        guard let startIndex = qualityOrder.firstIndex(of: highestQuality) else { return nil }
        
        for i in startIndex..<qualityOrder.count {
            let qualityType = qualityOrder[i]
            let (videoTypeId, _) = qualityType.typeIdentifiers()
            if let _ = streams[videoTypeId] {
                return qualityType
            }
        }
        
        return nil
    }
    
    fileprivate static func getVideoStream(streams: Dictionary<Int, URL>, for quality: VideoFormatType) -> VideoStream? {
        let (videoTypeId, audioTypeId) = quality.typeIdentifiers()
        guard let videoURL = streams[videoTypeId] else { return nil }
        var audioURL: URL?
        if let audioTypeId = audioTypeId {
            guard let unoptionalAudioURL = streams[audioTypeId] else { return nil }
            audioURL = unoptionalAudioURL
        }
        
        return VideoStream(videoURL: videoURL, audioURL: audioURL, videoFormatType: quality)
    }
}
