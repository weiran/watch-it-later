//
//  ViewController.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 25/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import UIKit
import AVKit

import XCDYouTubeKit
import YTVimeoExtractor

class ViewController: UIViewController, BookmarksDelegateProtocol {
    
    fileprivate let instapaperAPI = InstapaperAPI()
    fileprivate var bookmarks: [Bookmark]?
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        instapaperAPI.delegate = self
        instapaperAPI.storedAuth()
        instapaperAPI.fetch()
    }
    
    func bookmarksUpdated(bookmarks: [Bookmark]) {
        self.bookmarks = bookmarks.filter({ (bookmark) -> Bool in
            bookmark.url.contains("vimeo.com") || bookmark.url.contains("youtube.com") || bookmark.url.contains("youtu.be")
        })
        tableView.reloadData()
    }
}

// Table View
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell") as! BookmarkCell
        let bookmark = bookmarks![indexPath.row]
        cell.titleLabelView.text = bookmark.title
        
        if bookmark.url.contains("vimeo.com") {
            cell.domainLabelView.text = "vimeo.com"
            YTVimeoExtractor.shared().fetchVideo(withVimeoURL: bookmark.url, withReferer: nil) { (video, error) in
                if let thumbnailURLs = video?.thumbnailURLs, thumbnailURLs.count > 0 {
                    cell.thumbnailImageView.imageURL = thumbnailURLs[NSNumber(value: YTVimeoVideoThumbnailQuality.HD.rawValue)]
                }
            }
        } else if bookmark.url.contains("youtube.com") || bookmark.url.contains("youtu.be") {
            cell.domainLabelView.text = "youtube.com"
            let identifier = parseYoutubeIdentifier(bookmark.url)
            XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { (video, error) in
                cell.thumbnailImageView.imageURL = video?.largeThumbnailURL ?? video?.mediumThumbnailURL ?? video?.smallThumbnailURL
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bookmark = bookmarks![indexPath.row]
        if bookmark.url.contains("vimeo.com") {
            playVimeoVideo(url: bookmark.url)
        } else {
            playYouTubeVideo(url: bookmark.url)
        }
    }
    
}

// Video Playback
extension ViewController {
    
    func playYouTubeVideo(url: String!) {
        let identifier = parseYoutubeIdentifier(url)
        XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { (video, error) in
            
            if let streamURLs = video?.streamURLs, let streamURL = (streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?? streamURLs[YouTubeVideoQuality.hd720] ?? streamURLs[YouTubeVideoQuality.medium360] ?? streamURLs[YouTubeVideoQuality.small240]) {
                // TODO: need to combine audio and video tracks for dash: http://stackoverflow.com/questions/40113274/avasset-with-separate-video-and-audio-urls-ios
                let player = AVPlayer(url: streamURL)
                let videoPlayerViewController = AVPlayerViewController()
                videoPlayerViewController.player = player
                self.present(videoPlayerViewController, animated: true) {
                    videoPlayerViewController.player?.play()
                }
            }
            
        }
    }
    
    func playVimeoVideo(url: String!) {
        YTVimeoExtractor.shared().fetchVideo(withVimeoURL: url, withReferer: nil) { (video, error) in
            
            if let streamURL = video?.highestQualityStreamURL() {
                let player = AVPlayer(url: streamURL)
                let videoPlayerViewController = AVPlayerViewController()
                videoPlayerViewController.player = player
                self.present(videoPlayerViewController, animated: true) {
                    videoPlayerViewController.player?.play()
                }
            }
            
        }
    }
    
    fileprivate func parseYoutubeIdentifier(_ url: String) -> String {
        do {
            let identifierRegex = try NSRegularExpression(pattern: "(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)")
            let results = identifierRegex.matches(in: url, range: NSRange(location: 0, length: url.characters.count))
            if results.count > 0 {
                let urlNSString = url as NSString
                return urlNSString.substring(with: results.first!.range)
            } else {
                return ""
            }
        } catch _ {
            return ""
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
