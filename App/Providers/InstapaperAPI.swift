//
//  InstapaperAPI.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 28/12/2016.
//  Copyright Â© 2016 Weiran Zhang. All rights reserved.
//

import Locksmith
import PromiseKit
import RealmSwift

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
        let (consumerKey, consumerSecret) = InstapaperAPI.getOAuthConfiguration()
        IKEngine.setOAuthConsumerKey(consumerKey, andConsumerSecret: consumerSecret)
        engine = IKEngine()
        
        super.init()
        
        engine.delegate = self
    }
    
    fileprivate static func getOAuthConfiguration() -> (String?, String?) {
        var result: (String?, String?) = (nil, nil)
        if let path = Bundle.main.path(forResource: "InstapaperConfiguration", ofType: "plist") {
            if let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] {
                result = (dictionary["OAuthConsumerKey"], dictionary["OAuthConsumerSecret"])
            }
        }
        return result
    }
    
    @discardableResult
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
    
    @discardableResult
    func storedAuth() -> Promise<Void> {
        return Promise { fulfill, reject in
            let keys = Locksmith.loadDataForUserAccount(userAccount: InstapaperAPI.name)
            if let token = keys?["token"] as? String, let secret = keys?["secret"] as? String {
                engine.oAuthToken = token
                engine.oAuthTokenSecret = secret
                fulfill(())
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
    
    func archive(id: Int) {
        let bookmark = IKBookmark(bookmarkID: id)
        engine.archiveBookmark(bookmark, userInfo: nil)
    }
    
    func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveAuthToken token: String!, andTokenSecret secret: String!) {
        do {
            try? Locksmith.deleteDataForUserAccount(userAccount: InstapaperAPI.name)
            try Locksmith.saveData(data: ["token": token, "secret": secret], forUserAccount: InstapaperAPI.name)
            self.engine.oAuthToken = token
            self.engine.oAuthTokenSecret = secret
            loginFulfill?(())
        } catch {
            loginReject?(error)
        }
        
        clearLoginPromise()
    }
    
    func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveBookmarks bookmarks: [Any]!, of user: IKUser!, for folder: IKFolder!) {
        if let bookmarks = bookmarks as! [IKBookmark]? {
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
