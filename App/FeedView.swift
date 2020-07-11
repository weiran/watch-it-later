//
//  FeedView.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 11/07/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import SwiftUI
import PromiseKit

struct FeedView: View {
    let instapaperAPI = InstapaperAPI()
    @State var videos: [Video] = [Video]()

    let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 60))
    ]

    init() {
        fetchVideos()
    }

    init(videos: [Video]) {
        self.videos = videos
    }

    func fetchVideos() {
        _ = firstly {
            instapaperAPI.fetch([InstapaperFolder.unread.rawValue])
        }.done { bookmarks in
            let videos = bookmarks.filter {
                ($0.urlString.contains("vimeo.com") || $0.urlString.contains("youtube.com") || $0.urlString.contains("youtu.be"))
            }

            let syncedVideos = videos.map { video -> (Video) in
                if let existingVideo = Database.shared.getVideo(id: video.id) {
                    return existingVideo
                } else {
                    Database.shared.addVideo(video)
                    return video
                }
            }

            self.videos = syncedVideos
        }
    }

    var body: some View {
        ScrollView([.vertical]) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(videos, id: \.self) { video in
                    Text(video.title)
                }
            }
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(videos: [
            Video(dummyData: true),
            Video(dummyData: true),
            Video(dummyData: true)
        ])
    }
}
