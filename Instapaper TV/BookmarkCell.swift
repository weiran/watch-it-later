//
//  BookmarkCell.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 28/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import UIKit
import AsyncImageView

class BookmarkCell: UITableViewCell {

    @IBOutlet weak var titleLabelView: UILabel!
    @IBOutlet weak var domainLabelView: UILabel!
    @IBOutlet weak var thumbnailImageView: AsyncImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
