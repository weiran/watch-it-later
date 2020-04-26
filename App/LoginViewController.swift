//
//  LoginViewController.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 31/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit
import PromiseKit

class LoginViewController: UIViewController {
    var instapaperAPI: InstapaperAPI?
    private var hasStoredCredentials = false

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        instapaperAPI?.storedAuth().done { [weak self] in
            self?.hasStoredCredentials = true
        }.cauterize()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    @IBAction func didLogin(_ sender: Any) {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        if let username = usernameTextField.text, let password = passwordTextField.text {
            instapaperAPI?.login(username: username, password: password).done { [weak self] in
                self?.dismiss(animated: true)
                NotificationCenter.default.post(name: NSNotification.Name("AuthenticationChanged"), object: self)
            }.ensure { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.view.isUserInteractionEnabled = true
            }.catch { error in
                if error.localizedDescription.contains("503") {
                    // GDPR block
                    self.showError(title: "Instapaper temporarily unavailable", message: "Instapaper is temporarily unavailable for residents in Europe due to GDPR. Please contact support@instapaper.com for more information.\n\nWatch It Later has no ability to affect this.")
                } else if error.localizedDescription.contains("401") {
                    // invalid credentials
                    self.showError(title: "Couldn't log in", message: "The username and password you entered are incorrect.")
                } else {
                    // other error
                    self.showError(title: "Couldn't log in", message: "There was an problem logging in.")
                }
            }
        }
    }
    
    private func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
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
