//
//  PreferencesViewController.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 24/03/2018.
//  Copyright © 2018 Weiran Zhang. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class PreferencesViewController: UITableViewController {
    @IBOutlet weak var youTubeFormatTypeLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let youTubeFormatType = Defaults[\.defaultVideoQualityKey] {
            youTubeFormatTypeLabel.text = formatName(for: youTubeFormatType)
        }
    }
    
    func formatName(for formatType: VideoFormatType) -> String {
        switch formatType {
            case .video2160p60: return "4K60"
            case .video2160p: return "4K"
            case .video1440p60: return "1440p60"
            case .video1440p: return "1440p"
            case .video1080p60: return "1080p60"
            case .video1080p: return "1080p"
            case .video720p60: return "720p60"
            case .video720p: return "720p"
            case .video480p: return "480p"
            case .video360p: return "360p"
        }
    }
}
