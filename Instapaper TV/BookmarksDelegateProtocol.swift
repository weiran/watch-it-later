//
//  BookmarksProtocol.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 28/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//


protocol BookmarksDelegateProtocol: class {

    func bookmarksUpdated(bookmarks: [Bookmark])
    
}
