//
//  SwinjectStoryboardExtension.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 14/06/2018.
//  Copyright © 2018 Weiran Zhang. All rights reserved.
//

import SwinjectStoryboard

extension SwinjectStoryboard {
    @objc class func setup() {
        let container = defaultContainer
        container.storyboardInitCompleted(ViewController.self) { r, c in
            c.instapaperAPI = r.resolve(InstapaperAPI.self)!
        }
        container.storyboardInitCompleted(LoginViewController.self) { r, c in
            c.instapaperAPI = r.resolve(InstapaperAPI.self)!
        }
        container.storyboardInitCompleted(DetailViewController.self) { r, c in
            c.instapaperAPI = r.resolve(InstapaperAPI.self)!
        }
        container.register(InstapaperAPI.self) { _ in InstapaperAPI() }
            .inObjectScope(.container)
    }
}
