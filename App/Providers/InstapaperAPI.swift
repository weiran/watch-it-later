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
    
    private var loginSeal: Resolver<Void>?
    private var fetchSeal: Resolver<[Video]>?
    
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
        let (promise, seal) = Promise<Void>.pending()
        
        self.loginSeal = seal
        self.engine.authToken(forUsername: username, password: password, userInfo: nil)
        
        return promise
    }
    
    var loggedIn: Bool {
        get {
            return engine.oAuthToken != nil && engine.oAuthTokenSecret != nil
        }
    }
    
    @discardableResult
    func storedAuth() -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        
        let keys = Locksmith.loadDataForUserAccount(userAccount: InstapaperAPI.name)
        if let token = keys?["token"] as? String, let secret = keys?["secret"] as? String {
            engine.oAuthToken = token
            engine.oAuthTokenSecret = secret
            seal.fulfill(())
        } else {
            seal.reject("Couldn't get authentication credentials in keychain")
        }
        
        return promise
    }
    
    func fetch() -> Promise<[Video]> {
        let (promise, seal) = Promise<[Video]>.pending()
        
        self.fetchSeal = seal
        engine.bookmarks(in: IKFolder.unread(), limit: 500, existingBookmarks: nil, userInfo: nil)

        return promise
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
            loginSeal?.fulfill(())
        } catch {
            loginSeal?.reject(error)
        }
        
        loginSeal = nil
    }
    
    func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveBookmarks bookmarks: [Any]!, of user: IKUser!, for folder: IKFolder!) {
        if let bookmarks = bookmarks as! [IKBookmark]? {
            let videos = bookmarks.map { (bookmark) -> Video in
                return Video(bookmark)
            }
            fetchSeal?.fulfill(videos)
            fetchSeal = nil
        }
    }
    
    func engine(_ engine: IKEngine!, didFail connection: IKURLConnection!, error: Error!) {
        switch connection.type {
        case .authAccessToken:
            loginSeal?.reject(error)
            loginSeal = nil
            
        case .bookmarksList:
            fetchSeal?.reject(error)
            fetchSeal = nil
            
        default:
            return
        }
    }
}
