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

import Nuke
import PromiseKit
import SwiftyUserDefaults

class DetailViewController: UIViewController {
    var instapaperAPI: InstapaperAPI?
    var video: Video?
    var canArchive = true

    private var videoProvider: VideoProviderProtocol?
    private var videoStream: VideoStream?
    private var duration: CMTime?

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

        instapaperAPI?.storedAuth().cauterize()
        
        durationLabel.text = " "
        qualityLabel.text = " "
        descriptionLabel.text = " "
        
        if let video = video {
            titleLabel.text = video.title
            domainLabel.text = video.urlString.contains("vimeo.com") ? "vimeo.com" : "youtube.com"

            guard let videoProvider = try? VideoProvider.videoProvider(for: video.urlString) else {
                return
            }
            
            self.videoProvider = videoProvider
            videoProvider.videoStream().done { [weak self] (videoStream) in
                if let imageView = self?.thumbnailImageView, let url = videoStream.thumbnailURL {
                    let options = ImageLoadingOptions(placeholder: UIImage(named: "ThumbnailPlaceholder"))
                    Nuke.loadImage(with: url, options: options, into: imageView)
                }
                self?.durationLabel.text = self?.formatTimeInterval(duration: videoStream.duration)
                self?.duration = CMTime(seconds: videoStream.duration, preferredTimescale: CMTimeScale(videoStream.duration * 60))
                if let format = videoStream.videoFormatType {
                    self?.qualityLabel.text = format.description()
                }
                if let title = videoStream.title {
                    self?.titleLabel.text = title
                }
                if var description = videoStream.description {
                    description = description.replacingOccurrences(of: #"\[.*.\] "#, with: "", options: .regularExpression)
                    self?.descriptionLabel.text = description
                }
            }.cauterize()
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

        // try to open the video in the YouTube app first
        if videoProvider is YouTubeProvider, let url = self.video?.urlString {
            let regex = try! NSRegularExpression(pattern: #"([^\/|=]*$)"#, options: .caseInsensitive)
            let range = NSRange(location: 0, length: url.utf16.count)

            if let youtubeIdMatch = regex.firstMatch(in: url, options: [], range: range),
               youtubeIdMatch.range(at: 0).location != NSNotFound {
               let lowerBound = url.index(url.startIndex, offsetBy: youtubeIdMatch.range(at: 0).location)
               let youtubeId = url[lowerBound...]

                if let youtubeURL = URL(string: "youtube://watch/\(youtubeId)") {
                    if UIApplication.shared.canOpenURL(youtubeURL) {
                        UIApplication.shared.open(youtubeURL, options: [:], completionHandler: nil)
                        return
                    }
                }
            }
        }

        // play Vimeo using native player
        if videoProvider is VimeoProvider {
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
            videoProvider.videoStream().done { [weak self] videoStream -> Void in
                self?.videoStream = videoStream
                self?.showVideoPlayer()
            }.ensure { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.view.isUserInteractionEnabled = true
            }.catch { [weak self] error in
                self?.showError(error)
            }
        }
    }
    
    @IBAction func didArchive(_ sender: Any) {
        if let video = video, let instapaperAPI = instapaperAPI {
            instapaperAPI.archive(id: video.id).done { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }.catch { [weak self] error in
                let alert = UIAlertController(
                    title: "Error archiving", message: "There was a problem archiving this video.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func showVideoPlayer(startFrom: Int? = nil) {
        if let videoStream = videoStream {
            let player = AVPlayer(url: videoStream.videoURL)

            if let startFrom = startFrom, startFrom > 0 {
                let time = CMTimeMakeWithSeconds(Double(startFrom), preferredTimescale: 1)
                player.seek(to: time)
            }

            let controller = AVPlayerViewController()
            controller.player = player

            present(controller, animated: true) {
                player.play()
            }
        }
    }
    
    private func showError(_ error: Error? = nil) {
        var message = "Watch It Later couldn't play this video."

        if let error = error,
           let failureReason = (error as NSError).userInfo[NSLocalizedFailureReasonErrorKey] as? String {
            message = failureReason
        }

        let alert = UIAlertController(
            title: "Error Opening Video",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
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
