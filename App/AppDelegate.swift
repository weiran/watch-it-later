//
//  AppDelegate.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 25/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit
import SVProgressHUD
import SwiftyUserDefaults

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        SVProgressHUD.setRingThickness(12)
        SVProgressHUD.setRingNoTextRadius(64)
        
        _ = Database.shared
        
        if Defaults[.defaultVideoQualityKey] == nil {
           Defaults[.defaultVideoQualityKey] = .video1080p60
        }
        
        return true
    }
}
