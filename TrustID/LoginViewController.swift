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

//This is not safe but because of time yolo
public var dataPacket = Data()

class LoginViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
        GIDSignIn.sharedInstance()?.presentingViewController = self
        Auth.auth().addStateDidChangeListener { (auth, user) in
          if Auth.auth().currentUser != nil {
            self.performSegue(withIdentifier: "LoginSegue", sender: nil)
          }
        }
        guard let signIn = GIDSignIn.sharedInstance() else { return }
        if (signIn.hasPreviousSignIn()) {
            signIn.restorePreviousSignIn()
            if Auth.auth().currentUser != nil {
                print("already in")
                performSegue(withIdentifier: "LoginSegue", sender: nil)
            } else {
                print("no user")
            }
        } else {
            print("signing in...")
            GIDSignIn.sharedInstance().signIn()
            //print("Auth Status: " + (Auth.auth().currentUser?.email)!)
            //No previous signin
        }
    }
    


}
