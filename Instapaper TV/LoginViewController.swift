//
//  LoginViewController.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 31/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    var instapaperAPI: InstapaperAPI?
    private var hasStoredCredentials = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = instapaperAPI?.storedAuth().then { [weak self] (Void) -> Void in
            self?.hasStoredCredentials = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    @IBAction func didLogin(_ sender: Any) {
        if let username = usernameTextField.text, let password = passwordTextField.text {
            instapaperAPI?.login(username: username, password: password).then { Void -> Void in
                // login successful
                self.dismiss(animated: true)
                NotificationCenter.default.post(name: NSNotification.Name("AuthenticationChanged"), object: self)
            }.catch { error in
                self.showError()
            }
        }
    }
    
    private func showError() {
        DispatchQueue(label: "ErrorQueue").sync {
            let alertController = UIAlertController(title: "Login Error", message: "Couldn't login with your username and password.", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default, handler:nil)
            alertController.addAction(alertAction)
            present(alertController, animated: true)
        }
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
