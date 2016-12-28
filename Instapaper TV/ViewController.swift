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

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// Table View
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "VideoCell")!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        playVimeoVideo(url: "https://vimeo.com/channels/staffpicks/147876560")
        playYouTubeVideo(url: "https://www.youtube.com/watch?v=OVYF4t-v6Zw")
    }
    
    
}

// Video Playback
extension ViewController {
    
    func playYouTubeVideo(url: String!) {
        var identifier: String
        
        do {
            let identifierRegex = try NSRegularExpression(pattern: "(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)")
            let results = identifierRegex.matches(in: url, range: NSRange(location: 0, length: url.characters.count))
            if results.count > 0 {
                let urlNSString = url as NSString
                identifier = urlNSString.substring(with: results.first!.range)
            } else {
                // invalid url
                return
            }
        } catch _ {
            // invalid regex
            return
        }
        
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

