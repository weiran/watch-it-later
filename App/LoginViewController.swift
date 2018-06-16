//
//  LoginViewController.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 31/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var instapaperAPI: InstapaperAPI?
    private var hasStoredCredentials = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        instapaperAPI?.storedAuth().then { [weak self] in
            self?.hasStoredCredentials = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    @IBAction func didLogin(_ sender: Any) {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        if let username = usernameTextField.text, let password = passwordTextField.text {
            instapaperAPI?.login(username: username, password: password)
            .then { Void -> Void in
                // login successful
                self.dismiss(animated: true)
                NotificationCenter.default.post(name: NSNotification.Name("AuthenticationChanged"), object: self)
            }.catch { error in
                // 401 is bad credentials
                // 503 is EU
                self.showError()
            }.always { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.view.isUserInteractionEnabled = true
            }
        }
    }
    
    private func showError(isGDPRBlock: Bool = false) {
        let message = isGDPRBlock ? "Instapaper is currently blocking all EU customers due to GDPR. Unfortunately there is nothing this app can do about that." : "Couldn't login with your username and password."
        let alertController = UIAlertController(title: "Login Error", message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler:nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.first?.type == .menu && !hasStoredCredentials {
            exit(EXIT_SUCCESS)
        }
        super.pressesBegan(presses, with: event)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passwordTextField {
            didLogin(textField)
        }
        return true
    }
}
