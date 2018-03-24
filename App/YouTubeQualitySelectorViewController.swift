//
//  YouTubeQualitySelectorViewController.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 24/03/2018.
//  Copyright © 2018 Weiran Zhang. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class YouTubeQualitySelectorViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // set selection to current value
        let defaultYouTubeQuality = Defaults[DefaultsKeys.defaultYouTubeQualityKey]
        let selectedIndexPath = indexPath(for: defaultYouTubeQuality)
        self.tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFormatType = formatType(for: indexPath)
        Defaults[DefaultsKeys.defaultYouTubeQualityKey] = selectedFormatType
        
        self.dismiss(animated: true)
    }
    
    func formatType(for indexPath: IndexPath) -> YouTubeFormatType {
        switch indexPath.row {
            case 0: return .video1440p60
            case 1: return .video1440p
            case 2: return .video1080p60
            case 3: return .video1080p
            case 4: return .video720p60
            case 5: return .video720p
            default: return .video480p
        }
    }
    
    func indexPath(for formatType: YouTubeFormatType?) -> IndexPath {
        guard let unwrappedFormatType = formatType else {
            return IndexPath(row: 0, section: 0)
        }
        
        switch unwrappedFormatType {
        case .video1440p60: return IndexPath(row: 0, section: 0)
        case .video1440p: return IndexPath(row: 1, section: 0)
        case .video1080p60: return IndexPath(row: 2, section: 0)
        case .video1080p: return IndexPath(row: 3, section: 0)
        case .video720p60: return IndexPath(row: 4, section: 0)
        case .video720p: return IndexPath(row: 5, section: 0)
        default: return IndexPath(row: 0, section: 0)
        }
    }
}

extension DefaultsKeys {
    static let defaultYouTubeQualityKey = DefaultsKey<YouTubeFormatType?>("defaultYouTubeQuality")
}

extension UserDefaults {
    subscript(key: DefaultsKey<YouTubeFormatType?>) -> YouTubeFormatType? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
}
