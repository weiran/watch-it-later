//
//  DetailViewController.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit
import AVKit
import TVUIKit

import Kingfisher
import PromiseKit
import TVVLCPlayer
import SwiftyUserDefaults

class DetailViewController: UIViewController {
    var instapaperAPI: InstapaperAPI?
    var video: Video?
    var canArchive = true

    private var videoProvider: VideoProviderProtocol?
    private var videoStream: VideoStream?
    private var duration: CMTime?
    private var playerViewController: VLCPlayerViewController?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var qualityLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var archiveButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var buttonsStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        durationLabel.text = " "
        qualityLabel.text = " "
        
        if let video = video {
            titleLabel.text = video.title
            domainLabel.text = video.urlString.contains("vimeo.com") ? "vimeo.com" : "youtube.com"
            
            if let videoProvider = try? VideoProvider.videoProvider(for: video.urlString) {
                self.videoProvider = videoProvider
                videoProvider.videoStream(preferredFormatType: Defaults[\.defaultVideoQualityKey]).done { [weak self] (videoStream) in
                    self?.thumbnailImageView.kf.setImage(with: videoStream.thumbnailURL)
                    self?.durationLabel.text = self?.formatTimeInterval(duration: videoStream.duration)
                    self?.duration = CMTime(seconds: videoStream.duration, preferredTimescale: CMTimeScale(videoStream.duration * 60))
                    if let format = videoStream.videoFormatType {
                        self?.qualityLabel.text = format.description()
                    }
                }.cauterize()
                self.descriptionLabel.text = " "
            }
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didPlay(_:)))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        view.addGestureRecognizer(tapRecognizer)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        thumbnailImageView.layer.shadowRadius = 20
        thumbnailImageView.layer.shadowOpacity = 0.4
        thumbnailImageView.layer.shadowColor = UIColor.black.cgColor
        
        let playButton = TVCaptionButtonView()
        playButton.contentImage = UIImage(named: "PlayIcon")
        playButton.title = "Play"
        playButton.frame = CGRect(x: 0, y: 0, width: 90, height: 90)
        playButton.addTarget(self, action: #selector(didPlay(_:)), for: .primaryActionTriggered)
        buttonsStackView.insertArrangedSubview(playButton, at: 0)

        if canArchive {
            let archiveButton = TVCaptionButtonView()
            archiveButton.contentImage = UIImage(named: "ArchiveIcon")
            archiveButton.title = "Archive"
            archiveButton.frame = CGRect(x: 0, y: 0, width: 90, height: 90)
            archiveButton.addTarget(self, action: #selector(didArchive(_:)), for: .primaryActionTriggered)
            buttonsStackView.insertArrangedSubview(archiveButton, at: 1)
        }
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
        videoProvider.videoStream(preferredFormatType: Defaults[\.defaultVideoQualityKey]).done { [weak self] videoStream -> Void in
            guard let self = self, let video = self.video else {
                return
            }
            self.videoStream = videoStream
            
            if let alertController = self.playFromPositionAlertController(video) {
                self.present(alertController, animated: true)
            } else {
                self.showVideoPlayer()
            }
        }.ensure { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.view.isUserInteractionEnabled = true
        }.catch { [weak self] error in
            self?.showError()
        }
    }
    
    @IBAction func didArchive(_ sender: Any) {
        if let video = video, let instapaperAPI = instapaperAPI {
            instapaperAPI.archive(id: video.id).done { [weak self] in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "VideoArchived"), object: sender, userInfo: ["video": video])
                self?.dismiss(animated: true, completion: nil)
            }.catch { [weak self] error in
                guard let self = self else { return }
                let alert = UIAlertController(
                    title: "Error archiving", message: "There was a problem archiving this video.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }
    
    private func showVideoPlayer(startFrom: Int? = nil) {
        if startFrom == nil || startFrom! <= 0 {
            updateVideoProgress()
        }
        performSegue(withIdentifier: "ShowPlayerSegue", sender: self)
    }
    
    private func playFromPositionAlertController(_ video: Video) -> UIAlertController? {
        guard video.progress > 0 else { return nil }

        let progressInSeconds = video.progress / 1000
        let formattedProgress = formatTimeInterval(duration: TimeInterval(progressInSeconds))
        let alertController = UIAlertController(title: "", message: "Do you want to resume playback from your last saved position, or start from the beginning?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Resume from \(formattedProgress)", style: .default, handler: { action in
            self.showVideoPlayer(startFrom: video.progress)
        }))
        alertController.addAction(UIAlertAction(title: "Start from beginning", style: .default, handler: { action in
            self.showVideoPlayer(startFrom: 0)
        }))

        return alertController
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPlayerSegue" {
            if let playerViewController = segue.destination as? VLCPlayerViewController,
                let videoStream = self.videoStream {
                let player = VLCMediaPlayer()
                player.media = VLCMedia(url: videoStream.videoURL)
                playerViewController.player = player
                
                if let audioURL = videoStream.audioURL {
                    playerViewController.player.addPlaybackSlave(audioURL, type: .audio, enforce: true)
                }
                
                if let video = self.video, video.progress > 0 {
                    let time = VLCTime.init(number: NSNumber(value: video.progress))
                    playerViewController.player.time = time
                }
                
                playerViewController.player.delegate = self
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

extension DetailViewController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        guard let playerViewController = self.playerViewController else { return }
        if playerViewController.player.state == .ended {
            updateVideoProgress()
        } else if playerViewController.player.state == .stopped {
            updateVideoProgress(Int(playerViewController.player.time.intValue))
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        guard let player = self.playerViewController?.player else { return }
        if player.state == .playing || player.state == .buffering {
            updateVideoProgress(Int(player.time.intValue))
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
