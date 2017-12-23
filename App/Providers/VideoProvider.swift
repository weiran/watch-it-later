//
//  VideoProvider.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

class VideoProvider {
    static func videoProvider(for url: String) throws -> VideoProviderProtocol {
        if url.contains("vimeo.com") {
            return try VimeoProvider(url)
        } else if url.contains("youtube.com") || url.contains("youtu.be") {
            return try YouTubeProvider(url)
        } else {
            throw VideoError.InvalidURL
        }
    }
}
