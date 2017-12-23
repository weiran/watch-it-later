//
//  Video.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 28/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import RealmSwift
import CoreMedia

class Video: Object {
    convenience init(_ bookmark: IKBookmark) {
        self.init()

        id = bookmark.bookmarkID
        title = bookmark.title
        date = bookmark.date
        urlString = bookmark.url.absoluteString
    }

    @objc dynamic var id: Int = 0
    @objc dynamic var title: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var urlString: String = ""
    @objc dynamic var progress: Data?
    
    var url: URL? {
        if let url = URL(string: urlString) {
            return url
        }
        return nil
    }
    
    var progressTime: CMTime? {
        if let progress = progress, let time = NSKeyedUnarchiver.unarchiveObject(with: progress) as? CMTime {
            return time
        }
        return nil
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["url", "progressTime"]
    }
    
    static func == (left: Video, right: Video) -> Bool {
        return left.id == right.id
    }
}
