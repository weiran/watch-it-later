//
//  Video.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 28/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

class Video: Equatable {
    
    init(_ bookmark: IKBookmark) {
        title = bookmark.title
        description = bookmark.descr
        url = bookmark.url.absoluteString
        self.bookmark = bookmark
    }

    var title: String
    var description: String
    var url: String
    
    var bookmark: IKBookmark
    
    static func == (left: Video, right: Video) -> Bool {
        return left.bookmark == right.bookmark
    }
    
}
