//
//  AVPlayerViewController+Dismiss.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 07/05/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit
import AVKit

class AVPlayerViewControllerDismiss: AVPlayerViewController {
    var dismissDelegate: AVPlayerViewControllerDismissDelegate?
    
    open override func viewWillDisappear(_ animated: Bool) {
        self.dismissDelegate?.didDismissPlayerViewController()
        super.viewWillDisappear(animated)
    }
}

protocol AVPlayerViewControllerDismissDelegate {
    func didDismissPlayerViewController()
}
