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

class DetailViewController: UIViewController {
    
    var video: Video?
    var videoProvider: VideoProviderProtocol?
    var instapaperAPI: InstapaperAPI?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: AsyncImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let video = video {
            titleLabel.text = video.title
            domainLabel.text = video.url.contains("vimeo.com") ? "vimeo.com" : "youtube.com"
            descriptionLabel.text = video.description
            
            if let videoProvider = try? VideoProvider.videoProvider(for: video.url) {
                self.videoProvider = videoProvider
                _ = videoProvider.thumbnailURL().then { [weak self] url in
                    self?.thumbnailImageView.imageURL = url
                }
                _ = videoProvider.duration().then { [weak self] (duration: Double) in
                    self?.durationLabel.text = self?.formatTimeInterval(duration: duration)
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
        guard videoProvider != nil else {
            showError()
            return
        }
        
        SVProgressHUD.show()
        view.isUserInteractionEnabled = false
        _ = videoProvider!.streamURL().then { streamURL -> Void in
            let player = AVPlayer(url: streamURL)
            let videoPlayerViewController = AVPlayerViewController()
            videoPlayerViewController.player = player
            self.present(videoPlayerViewController, animated: true) {
                videoPlayerViewController.player!.play()
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.didFinishPlaying(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }
        .catch { [weak self] error in
            self?.showError()
        }.always {
            SVProgressHUD.dismiss()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func didArchive(_ sender: Any) {
        instapaperAPI?.archive(bookmark: video!.bookmark)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "VideoArchived"), object: sender, userInfo: ["video": video!])
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func didFinishPlaying(notification: NSNotification) {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
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
    
}
