//
//  Database.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 07/05/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import RealmSwift

class Database {
    static let shared = Database()
    private let realm: Realm
    
    init() {
        realm = try! Realm()
    }
    
    func getVideo(id: Int) -> Video? {
        if let video = realm.objects(Video.self).filter("id == \(id)").first {
            return video
        }
        return nil
    }
    
    func addVideo(_ video: Video) {
        if realm.objects(Video.self).filter("id == \(video.id)").count == 0 {
            try? realm.write {
                realm.add(video)
            }
        }
    }
    
    func deleteVideo(_ video: Video) {
        if let realmVideo = realm.objects(Video.self).first(where: { $0.id == video.id }) {
            try? realm.write {
                realm.delete(realmVideo)
            }
        }
    }
    
    func updateVideo(_ video: Video) {
        try? realm.write {
            realm.add(video)
        }
    }
    
    func updateVideoProgress(_ video: Video, progress: Data?) {
        try? realm.write {
            video.progress = progress
        }
    }
}
