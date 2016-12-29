//
//  YouTubeProvider.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import UIKit

import PromiseKit
import XCDYouTubeKit

class YouTubeProvider: VideoProviderProtocol {
    
    var url: URL
    var identifier: String
    
    required init(_ url: String) throws {
        self.url = URL(string: url)!
        self.identifier = ""
        self.identifier = try parseYoutubeIdentifier(url)
    }
    
    func streamURL() -> Promise<URL> {
        return Promise { fulfill, reject in
            XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { video, error in
                if let streamURLs = video?.streamURLs, let streamURL = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ??
                    streamURLs[YouTubeVideoQuality.hd720] ??
                    streamURLs[YouTubeVideoQuality.medium360] ??
                    streamURLs[YouTubeVideoQuality.small240] {
                    // TODO: need to combine audio and video tracks for dash: http://stackoverflow.com/questions/40113274/avasset-with-separate-video-and-audio-urls-ios
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
            XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { video, error in
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
    
    func description() -> Promise<String> {
        // figure out a way to get a YouTube description
        return Promise { fulfill, reject in
            fulfill("")
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
            let results = identifierRegex.matches(in: url, range: NSRange(location: 0, length: url.characters.count))
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
    
    
    struct YouTubeVideoQuality {
        
        static let dash1080p60 = NSNumber(value: 299)
        static let dash720p60 = NSNumber(value: 298)
        static let dash1080 = NSNumber(value: 137)
        static let dash720 = NSNumber(value: 136)
        
        static let hd720 = NSNumber(value: XCDYouTubeVideoQuality.HD720.rawValue)
        static let medium360 = NSNumber(value: XCDYouTubeVideoQuality.medium360.rawValue)
        static let small240 = NSNumber(value: XCDYouTubeVideoQuality.small240.rawValue)
        
    }
}
