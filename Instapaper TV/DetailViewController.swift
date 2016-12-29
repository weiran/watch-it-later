//
//  DetailViewController.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import UIKit
import AsyncImageView

class DetailViewController: UIViewController {
    
    var video: Video?

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
        }
        
    }

    @IBAction func didPlay(_ sender: Any) {
        if let video = video, video.url.contains("vimeo.com") {
//            playVimeoVideo(url: video.url)
        } else {
//            playYouTubeVideo(url: video.url)
        }
    }
    
    @IBAction func didArchive(_ sender: Any) {
        
    }
    
}
