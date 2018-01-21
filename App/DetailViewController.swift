//
//  DetailViewController.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit
import AVKit

import AsyncImageView
import PromiseKit
import SVProgressHUD

class DetailViewController: UIViewController, AVPlayerViewControllerDismissDelegate {
    var video: Video?
    var videoProvider: VideoProviderProtocol?
    var instapaperAPI: InstapaperAPI?
    
    var playerViewController: AVPlayerViewControllerDismiss?
    @objc var player: AVPlayer?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: AsyncImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var archiveButton: UIButton!
    
    var duration: CMTime?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let video = video {
            titleLabel.text = video.title
            domainLabel.text = video.urlString.contains("vimeo.com") ? "vimeo.com" : "youtube.com"
            
            if let videoProvider = try? VideoProvider.videoProvider(for: video.urlString) {
                self.videoProvider = videoProvider
                videoProvider.thumbnailURL().then { [weak self] url in
                    self?.thumbnailImageView.imageURL = url
                }
                videoProvider.duration().then { [weak self] (duration: Double) -> Void in
                    self?.durationLabel.text = self?.formatTimeInterval(duration: duration)
                    self?.duration = CMTime(seconds: duration, preferredTimescale: CMTimeScale(duration * 60))
                }
            }
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didPlay(_:)))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue)]
        view.addGestureRecognizer(tapRecognizer)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        thumbnailImageView.layer.shadowRadius = 10
        thumbnailImageView.layer.shadowOpacity = 0.5
        thumbnailImageView.layer.shadowColor = UIColor.black.cgColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.endReceivingRemoteControlEvents()
    }

    @IBAction func didPlay(_ sender: Any) {
        guard let videoProvider = videoProvider else {
            showError()
            return
        }
        
        SVProgressHUD.show()
        view.isUserInteractionEnabled = false
        videoProvider.videoStream().then { videoStream -> Void in
            var player: AVPlayer?
            let videoAsset = AVURLAsset(url: videoStream.videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
            
            if let audioURL = videoStream.audioURL {
                // dash stream
                // let duration = videoAsset.duration // TODO: this causes a network request
                let duration = self.duration!
                
                let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
                let videoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
                let videoTimeRange = CMTimeRange(start: kCMTimeZero, duration: duration)
                let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first
                try? videoTrack?.insertTimeRange(videoTimeRange, of: videoAssetTrack!, at: kCMTimeZero)
                
                let audioAsset = AVURLAsset(url: audioURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
                let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                try? audioTrack?.insertTimeRange(CMTimeRange(start: kCMTimeZero, duration: duration), of: audioAsset.tracks(withMediaType: .audio)[0], at: kCMTimeZero)
                
                let playerItem = AVPlayerItem(asset: composition)
                player = AVPlayer(playerItem: playerItem)
            } else {
                // standard stream
                player = AVPlayer(url: videoStream.videoURL)
            }
            
            let playerViewController = AVPlayerViewControllerDismiss()
            playerViewController.player = player
            playerViewController.dismissDelegate = self
            
            self.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
            
            self.playerViewController = playerViewController
            self.player = player
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.didFinishPlaying(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            
            player?.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        }
        .catch { [weak self] error in
            self?.showError()
        }.always {
            SVProgressHUD.dismiss()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func didArchive(_ sender: Any) {
        if let video = video, let instapaperAPI = instapaperAPI {
            instapaperAPI.archive(id: video.id)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "VideoArchived"), object: sender, userInfo: ["video": video])
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func didFinishPlaying(notification: NSNotification) {
        playerViewController?.dismiss(animated: true, completion: { [unowned self] in
            if let video = self.video {
                Database.shared.updateVideoProgress(video, progress: nil)
            }
        })
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func didDismissPlayerViewController() {
        self.player?.removeObserver(self, forKeyPath: "status")
        updateVideoProgress()
    }
    
    func updateVideoProgress() {
        if let video = video, let playerViewController = playerViewController, let player = playerViewController.player {
            let currentTime = player.currentTime()
            let timeData = NSKeyedArchiver.archivedData(withRootObject: currentTime)
            Database.shared.updateVideoProgress(video, progress: timeData)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbededVideos" {
            let videosViewController = segue.destination as! ViewController
            videosViewController.isChildViewController = true
            videosViewController.hideVideo = video
        }
    }
    
    private func showError() {
        let alertController = UIAlertController(title: "Video Error", message: "There's something wrong with the video and it can't be played.", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler:nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true)
    }
    
    func formatTimeInterval(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        
        if duration >= 3600 {
            formatter.allowedUnits = [.hour, .minute, .second]
        } else {
            formatter.allowedUnits = [.minute, .second]
        }
        
        return formatter.string(from: duration) ?? ""
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let player = object as? AVPlayer {
            if let video = video, player.status == .readyToPlay, let time = video.progressTime {
                player.seek(to: time)
            }
        }
    }
}
