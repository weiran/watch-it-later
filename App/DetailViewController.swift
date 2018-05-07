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
import TVVLCPlayer
import SwiftyUserDefaults

class DetailViewController: UIViewController {
    var video: Video?
    var videoProvider: VideoProviderProtocol?
    var instapaperAPI: InstapaperAPI?
    
    var videoStream: VideoStream?
    var duration: CMTime?
    
    var playerViewController: VLCPlayerViewController?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: AsyncImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var archiveButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        durationLabel.text = ""
        
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
                self.descriptionLabel.text = ""
            }
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didPlay(_:)))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue)]
        view.addGestureRecognizer(tapRecognizer)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        thumbnailImageView.layer.shadowRadius = 20
        thumbnailImageView.layer.shadowOpacity = 0.4
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
        
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        videoProvider.videoStream(preferredFormatType: Defaults[DefaultsKeys.defaultVideoQualityKey]).then { [weak self] videoStream -> Void in
            self?.videoStream = videoStream
            self?.performSegue(withIdentifier: "ShowPlayerSegue", sender: self)
        }
        .catch { [weak self] error in
            self?.showError()
        }.always { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.view.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func didArchive(_ sender: Any) {
        if let video = video, let instapaperAPI = instapaperAPI {
            instapaperAPI.archive(id: video.id)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "VideoArchived"), object: sender, userInfo: ["video": video])
        }
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPlayerSegue" {
            if let playerViewController = segue.destination as? VLCPlayerViewController,
                let videoStream = self.videoStream {
                let videoMedia = VLCMedia(url: videoStream.videoURL)
                playerViewController.media = videoMedia
                
                if let audioURL = videoStream.audioURL {
                    playerViewController.player.addPlaybackSlave(audioURL, type: .audio, enforce: true)
                }
                
                if let video = self.video, video.progress > 0 {
                    let time = VLCTime.init(number: NSNumber(value: video.progress))
                    playerViewController.player.time = time
                }
                
                playerViewController.delegate = self
                self.playerViewController = playerViewController
            }
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
}

extension DetailViewController: VLCMediaPlayerViewControllerDelegate {
    func mediaPlayer(_ playerViewController: VLCPlayerViewController, stateChanged state: VLCMediaPlayerState) {
        if state == .ended {
            updateVideoProgress()
        } else if state == .stopped {
            updateVideoProgress(Int(playerViewController.player.time.intValue))
        }
    }
    
    func mediaPlayer(_ playerViewController: VLCPlayerViewController, timeChanged time: VLCTime) {
        if playerViewController.player.state == .playing || playerViewController.player.state == .buffering {
            updateVideoProgress(Int(time.intValue))
        }
    }
    
    private func updateVideoProgress(_ duration: Int = 0) {
        if let video = video {
            Database.shared.updateVideoProgress(video, progress: duration)
        }
    }
}

extension VLCPlayerViewController {
    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.first?.type == .menu {
            // stop the player when quitting to trigger the delegate
            player.stop()
        }
        super.pressesBegan(presses, with: event)
    }
}
