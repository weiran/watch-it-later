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
    
    init(videoURL: URL, audioURL: URL?) {
        self.videoURL = videoURL
        self.audioURL = audioURL
    }
}
