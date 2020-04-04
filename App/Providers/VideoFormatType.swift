//
//  VideoFormatType.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 23/12/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import SwiftyUserDefaults

enum VideoFormatType: Int, DefaultsSerializable {
    case video2160p60 = 0
    case video2160p
    case video1440p60
    case video1440p
    case video1080p60
    case video1080p
    case video720p60
    case video720p
    case video480p
    case video360p
    
    func typeIdentifiers() -> (Int, Int?) {
        switch self {
        case .video2160p60:
            return (315, 140) // VP9
        case .video2160p:
            return (313, 140) // VP9
        case .video1440p60:
            return (308, 140) // VP9
        case .video1440p:
            return (271, 140) // VP9
        case .video1080p60:
            return (299, 140)
        case .video1080p:
            return (137, 140)
        case .video720p60:
            return (298, 140)
        case .video720p:
            return (22, nil)
        case .video480p:
            return (135, 140)
        case .video360p:
            return (18, nil)
        }
    }

    func description() -> String {
        switch self {
        case .video2160p60:
            return "2160p60 VP9"
        case .video2160p:
            return "2160p VP9"
        case .video1440p60:
            return "1440p60 VP9"
        case .video1440p:
            return "1440p VP9"
        case .video1080p60:
            return "1080p60"
        case .video1080p:
            return "1080p"
        case .video720p60:
            return "720p60"
        case .video720p:
            return "720p"
        case .video480p:
            return "480p"
        case .video360p:
            return "360p"
        }
    }
}
