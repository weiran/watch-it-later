//
//  VideoCell.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit
import TVUIKit
import Nuke

class VideoCell: UICollectionViewCell {
    var posterView: TVPosterView
    
    required init?(coder aDecoder: NSCoder) {
        let posterView = TVPosterView()
        self.posterView = posterView
        
        super.init(coder: aDecoder)
        
        posterView.frame = self.bounds
        setImage(image: UIImage.init(named: "ThumbnailPlaceholder")!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addSubview(posterView)
    }
    
    func setImage(image: UIImage) {
        posterView.image = image
        if let imageView = posterView.subviews[0].subviews[0] as? UIImageView {
            imageView.contentMode = .scaleAspectFill
        }
    }
    
    func setImageURL(url: URL) {
        if let imageView = posterView.subviews[0].subviews[0] as? UIImageView {
            imageView.contentMode = .scaleAspectFill
            let options = ImageLoadingOptions(placeholder: UIImage(named: "ThumbnailPlaceholder"))
            Nuke.loadImage(with: url, options: options, into: imageView)
        }
    }
}
