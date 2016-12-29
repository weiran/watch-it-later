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

class ViewController: UIViewController, VideosDelegateProtocol {
    
    fileprivate let instapaperAPI = InstapaperAPI()
    fileprivate var videos: [Video]?
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        instapaperAPI.delegate = self
        instapaperAPI.storedAuth()
        instapaperAPI.fetch()
    }
    
    func videosUpdated(videos: [Video]) {
        self.videos = videos.filter({ (video) -> Bool in
            video.url.contains("vimeo.com") || video.url.contains("youtube.com") || video.url.contains("youtu.be")
        })
        collectionView.reloadData()
    }
}


// Collection View
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
        let video = videos![indexPath.row]
        cell.titleLabel.text = video.title
        
        if video.url.contains("vimeo.com") {
            YTVimeoExtractor.shared().fetchVideo(withVimeoURL: video.url, withReferer: nil) { (video, error) in
                if let thumbnailURLs = video?.thumbnailURLs, thumbnailURLs.count > 0 {
                    cell.thumbnailImageView.imageURL = thumbnailURLs[NSNumber(value: YTVimeoVideoThumbnailQuality.HD.rawValue)]
                }
            }
        } else if video.url.contains("youtube.com") || video.url.contains("youtu.be") {
            let identifier = parseYoutubeIdentifier(video.url)
            XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { (video, error) in
                cell.thumbnailImageView.imageURL = video?.largeThumbnailURL ?? video?.mediumThumbnailURL ?? video?.smallThumbnailURL
            }
        }
        
        return cell
    }
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let bookmark = bookmarks![indexPath.row]
//        if bookmark.url.contains("vimeo.com") {
//            playVimeoVideo(url: bookmark.url)
//        } else {
//            playYouTubeVideo(url: bookmark.url)
//        }
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetailSegue" {
            let cell = sender as! VideoCell
            let indexPath = collectionView.indexPath(for: cell)!
            let video = videos?[indexPath.row]
            
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.video = video
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
