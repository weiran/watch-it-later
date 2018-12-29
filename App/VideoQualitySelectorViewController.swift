//
//  YouTubeQualitySelectorViewController.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 24/03/2018.
//  Copyright © 2018 Weiran Zhang. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class VideoQualitySelectorViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // set selection to current value
        let defaultVideoQuality = Defaults[DefaultsKeys.defaultVideoQualityKey]
        let selectedIndexPath = indexPath(for: defaultVideoQuality)
        self.tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: UITableView.ScrollPosition.none)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFormatType = formatType(for: indexPath)
        Defaults[DefaultsKeys.defaultVideoQualityKey] = selectedFormatType
        
        self.dismiss(animated: true)
    }
    
    func formatType(for indexPath: IndexPath) -> VideoFormatType {
        switch indexPath.row {
            case 0: return .video2160p
            case 1: return .video1440p
            case 2: return .video1080p60
            case 3: return .video1080p
            case 4: return .video720p60
            case 5: return .video720p
            case 6: return .video480p
            case 7: return .video360p
            default: return .video360p
        }
    }
    
    func indexPath(for formatType: VideoFormatType?) -> IndexPath {
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
            case .video480p: return IndexPath(row: 6, section: 0)
            case .video360p: return IndexPath(row: 7, section: 0)
            default: return IndexPath(row: 0, section: 0)
        }
    }
}

extension DefaultsKeys {
    static let defaultVideoQualityKey = DefaultsKey<VideoFormatType?>("defaultVideoQuality")
    static let newDefaultVideoQualityKey = DefaultsKey<VideoFormatType?>("newDefaultVideoQuality")
}

extension UserDefaults {
    subscript(key: DefaultsKey<VideoFormatType?>) -> VideoFormatType? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
}
