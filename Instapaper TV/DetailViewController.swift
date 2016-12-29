//
//  DetailViewController.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import UIKit
import AVKit

import AsyncImageView
import PromiseKit

class DetailViewController: UIViewController {
    
    var video: Video?
    var videoProvider: VideoProviderProtocol?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: AsyncImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let video = video {
            titleLabel.text = video.title
            domainLabel.text = video.url.contains("vimeo.com") ? "vimeo.com" : "youtube.com"
            descriptionLabel.text = video.description
            do {
                videoProvider = try VideoProvider.videoProvider(for: video.url)
                let thumbnailPromise = videoProvider!.thumbnailURL().then { [weak self] url in
                    self?.thumbnailImageView.imageURL = url
                }
                let descriptionPromise = videoProvider!.description().then { [weak self] description in
                    self?.descriptionLabel.text = description
                }
                
                when(fulfilled: [thumbnailPromise, descriptionPromise])
                .catch { [weak self] error in
                    self?.showError()
                }
            } catch _ {
                showError()
            }
        }
        
    }

    @IBAction func didPlay(_ sender: Any) {
        videoProvider!.streamURL().then { streamURL -> Void in
            let player = AVPlayer(url: streamURL)
            let videoPlayerViewController = AVPlayerViewController()
            videoPlayerViewController.player = player
            self.present(videoPlayerViewController, animated: true) {
                videoPlayerViewController.player!.play()
            }
        }
        .catch { [weak self] error in
            self?.showError()
        }
    }
    
    @IBAction func didArchive(_ sender: Any) {
        
    }
    
    fileprivate func showError() {
        let alertController = UIAlertController(title: "Video Error", message: "There's something wrong with the video.", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(alertAction)
        self.present(alertController, animated: true)    }
}
