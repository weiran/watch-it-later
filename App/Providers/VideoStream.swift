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
    let duration: Double
    let videoFormatType: VideoFormatType?
    let thumbnailURL: URL?
    
    init(
        videoURL: URL,
        audioURL: URL?,
        duration: Double,
        videoFormatType: VideoFormatType? = nil,
        thumbnailURL: URL?
    ) {
        self.videoURL = videoURL
        self.audioURL = audioURL
        self.duration = duration
        self.videoFormatType = videoFormatType
        self.thumbnailURL = thumbnailURL
    }
}
