//
//  FoldersTabBarController.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 26/04/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation

class FoldersTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let unreadViewController = viewController(for: .unread, with: storyboard)
        let starredViewController = viewController(for: .starred, with: storyboard)
        let archiveViewController = viewController(for: .archive, with: storyboard)
        let settingsViewController = storyboard.instantiateViewController(identifier: "SettingsViewController")

        self.viewControllers = [unreadViewController, starredViewController, archiveViewController, settingsViewController]

        guard let tabBarItems = self.tabBar.items else { return }
        for (index, element) in tabBarItems.enumerated() {
            switch index {
            case 0: element.title = "New"
            case 1: element.title = "Starred"
            case 2: element.title = "Archive"
            default: break
            }
        }
    }

    private func viewController(for folder: InstapaperFolder, with storyboard: UIStoryboard) -> ViewController {
        let viewController = storyboard.instantiateViewController(identifier: "ViewController") as ViewController
        viewController.folder = folder
        return viewController
    }
}
