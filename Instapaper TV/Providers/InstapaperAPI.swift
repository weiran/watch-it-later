//
//  InstapaperAPI.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 28/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import Locksmith

protocol API {
    static var name: String { get }
    
    func login()
    func storedAuth()
    func fetch()
}

class InstapaperAPI: NSObject, API, IKEngineDelegate {
    
    static var name = "Instapaper"
    private var engine: IKEngine
    weak var delegate: VideosDelegateProtocol?
    
    override init() {
        IKEngine.setOAuthConsumerKey("JhxaIHH9KhRc3Mj2JaiJ6bYOhMR5Kv7sdeESoBgxlEf51YOdtb", andConsumerSecret: "Yl6nzC2cVu2AGm8XrqoTt8QgVI0FJs0ndsV5jWbSN7bI3tBSb1")
        engine = IKEngine()
        
        super.init()
        
        engine.delegate = self
    }
    
    func login() {
        engine.authToken(forUsername: "weiran@zhang.me.uk", password: "bardev", userInfo: nil)
    }
    
    func storedAuth() {
        let keys = Locksmith.loadDataForUserAccount(userAccount: InstapaperAPI.name)
        if let token = keys?["token"], let secret = keys?["secret"] {
            engine.oAuthToken = token as? String
            engine.oAuthTokenSecret = secret as? String
        }
    }
    
    func fetch() {
        engine.bookmarks(withUserInfo: nil)
    }
    
    func archive(bookmark: IKBookmark) {
        engine.archiveBookmark(bookmark, userInfo: nil)
    }
    
    func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveAuthToken token: String!, andTokenSecret secret: String!) {
        do {
            try Locksmith.deleteDataForUserAccount(userAccount: InstapaperAPI.name)
            try Locksmith.saveData(data: ["token": token, "secret": secret], forUserAccount: InstapaperAPI.name)
        } catch {
            // todo: handle keychain error
        }
    }
    
    func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveBookmarks bookmarks: [Any]!, of user: IKUser!, for folder: IKFolder!) {
        if let bookmarks = bookmarks as! [IKBookmark]! {
            let videos = bookmarks.map { (bookmark) -> Video in
                return Video(bookmark)
            }
            delegate?.videosUpdated(videos: videos)
        }
    }
    
}
