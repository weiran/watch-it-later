//
//  VideoStream.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 23/12/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

struct VideoStream {
    let videoURL: URL!
    let audioURL: URL?
    let videoFormatType: VideoFormatType?
    
    init(videoURL: URL, audioURL: URL?, videoFormatType: VideoFormatType? = nil) {
        self.videoURL = videoURL
        self.audioURL = audioURL
        self.videoFormatType = videoFormatType
    }
}
