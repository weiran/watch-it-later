//
//  Video.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 28/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

class Video {
    
    init(_ bookmark: IKBookmark) {
        title = bookmark.title
        description = bookmark.descr
        url = bookmark.url.absoluteString
    }

    var title: String
    var description: String
    var url: String
    
}
