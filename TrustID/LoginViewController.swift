//
//  LoginViewController.swift
//  TrustID
//
//  Created by Harin Wu on 2020-02-08.
//  Copyright © 2020 TELUS. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FirebaseAuth

class LoginViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        guard let signIn = GIDSignIn.sharedInstance() else { return }
        if (signIn.hasPreviousSignIn()) {
            signIn.restorePreviousSignIn()
            if Auth.auth().currentUser != nil {
                print("already in")
                performSegue(withIdentifier: "LoginSegue", sender: nil)
            } else {
                GIDSignIn.sharedInstance().signIn()
                if Auth.auth().currentUser != nil {
                    print("in")
                    performSegue(withIdentifier: "LoginSegue", sender: nil)
                } else {
                    // No user is signed in.
                    // ...
                }
            }
        } else {
            GIDSignIn.sharedInstance().signIn()
            if Auth.auth().currentUser != nil {
                print("in")
                performSegue(withIdentifier: "LoginSegue", sender: nil)
            } else {
                // No user is signed in.
                // ...
            }
        }
    }
    


}
