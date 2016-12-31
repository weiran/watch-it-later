//
//  InstapaperAPI.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 28/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import Locksmith
import PromiseKit

protocol API {
    static var name: String { get }
    
    func login(username: String, password: String) -> Promise<Void>
    func storedAuth() -> Promise<Void>
    func fetch() -> Promise<[Video]>
}

class InstapaperAPI: NSObject, API, IKEngineDelegate {
    
    static var name = "Instapaper"
    private var engine: IKEngine
    
    private var loginFulfill: ((Void) -> Void)?
    private var loginReject: ((Error) -> Void)?
    
    private var fetchFulfill: (([Video]) -> Void)?
    private var fetchReject: ((Error) -> Void)?
    
    
    override init() {
        IKEngine.setOAuthConsumerKey("JhxaIHH9KhRc3Mj2JaiJ6bYOhMR5Kv7sdeESoBgxlEf51YOdtb", andConsumerSecret: "Yl6nzC2cVu2AGm8XrqoTt8QgVI0FJs0ndsV5jWbSN7bI3tBSb1")
        engine = IKEngine()
        
        super.init()
        
        engine.delegate = self
    }
    
    func login(username: String, password: String) -> Promise<Void> {
        return Promise { fulfill, reject in
            self.loginFulfill = fulfill
            self.loginReject = reject
            self.engine.authToken(forUsername: username, password: password, userInfo: nil)
        }
    }
    
    var loggedIn: Bool {
        get {
            return engine.oAuthToken != nil && engine.oAuthTokenSecret != nil
        }
    }
    
    func storedAuth() -> Promise<Void> {
        return Promise { fulfill, reject in
            let keys = Locksmith.loadDataForUserAccount(userAccount: InstapaperAPI.name)
            if let token = keys?["token"], let secret = keys?["secret"] {
                engine.oAuthToken = token as? String
                engine.oAuthTokenSecret = secret as? String
                fulfill()
            } else {
                reject("Couldn't get authentication credentials in keychain")
            }
        }
    }
    
    func fetch() -> Promise<[Video]> {
        return Promise<[Video]> { fulfill, reject in
            self.fetchFulfill = fulfill
            self.fetchReject = reject
            engine.bookmarks(in: IKFolder.unread(), limit: 500, existingBookmarks: nil, userInfo: nil)
        }
    }
    
    func archive(bookmark: IKBookmark) {
        engine.archiveBookmark(bookmark, userInfo: nil)
    }
    
    func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveAuthToken token: String!, andTokenSecret secret: String!) {
        do {
            try? Locksmith.deleteDataForUserAccount(userAccount: InstapaperAPI.name)
            try Locksmith.saveData(data: ["token": token, "secret": secret], forUserAccount: InstapaperAPI.name)
            loginFulfill?()
        } catch {
            loginReject?(error)
        }
        
        clearLoginPromise()
    }
    
    func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveBookmarks bookmarks: [Any]!, of user: IKUser!, for folder: IKFolder!) {
        if let bookmarks = bookmarks as! [IKBookmark]! {
            let videos = bookmarks.map { (bookmark) -> Video in
                return Video(bookmark)
            }
            fetchFulfill?(videos)
            clearFetchPromise()
        }
    }
    
    func engine(_ engine: IKEngine!, didFail connection: IKURLConnection!, error: Error!) {
        switch connection.type {
        
        case .authAccessToken:
            loginReject?(error)
            clearLoginPromise()
            
        case .bookmarksList:
            fetchReject?(error)
            clearFetchPromise()
            
        default:
            return
            
        }
    }
    
    private func clearLoginPromise() {
        loginReject = nil
        loginFulfill = nil
    }
    
    private func clearFetchPromise() {
        fetchReject = nil
        fetchFulfill = nil
    }
    
}
