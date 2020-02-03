//
//  ViewController.swift
//  TrustID
//
//  Created by Harin Wu on 2020-02-01.
//  Copyright © 2020 TELUS. All rights reserved.
//

import UIKit
import LocalAuthentication
import Firebase
import FirebaseUI

let db = Firestore.firestore()
let storage = Storage.storage()

class ViewController: UIViewController {
    @IBOutlet weak var AgeCheck: UIImageView!
    @IBOutlet weak var CanadaCheck: UIImageView!
    @IBOutlet weak var ResidentCheck: UIImageView!
    @IBOutlet weak var USCheck: UIImageView!
    @IBOutlet weak var PhotoCheck: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func ScanUser(_ sender: Any) {
        let context = LAContext()
        context.localizedCancelTitle = "Enter Username/Password"
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            let reason = "Log in to your account"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in

                if success {
                    // Move to the main thread because a state update triggers UI changes.
                    DispatchQueue.main.async { [unowned self] in
                        db.collection("Users").whereField("FirstName", isEqualTo: "Harin").whereField("LastName", isEqualTo: "Wu").getDocuments{ (querySnapshot, err) in
                            if let err = err {
                                print("Error getting documents: \(err)")
                            } else {
                                if (!querySnapshot!.documents.isEmpty) {
                                    self.checkData(User: UserInfo.init(ID: querySnapshot!.documents[0].documentID, data: querySnapshot!.documents[0].data()))
                                }
                            }
                        }
                    }

                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")
                    // Fall back to a asking for username and password.
                }
            }
            
        }
    }
    
    func checkData(User: UserInfo) {
        let components = Set<Calendar.Component>([.second, .minute, .hour, .day, .month, .year])
        let age = Calendar.current.dateComponents(components, from: User.Birthday.dateValue(), to: Timestamp.init().dateValue())
        if (age.year! >= 19) {
            AgeCheck.image = UIImage(named: "Check")
        } else {
            AgeCheck.image = UIImage(named: "Fail")
        }
        
        if (User.Citizen == "Canada") {
            CanadaCheck.image = UIImage(named: "Check")
        } else {
            CanadaCheck.image = UIImage(named: "Fail")
        }
        
        if (User.Resident == "Burnaby") {
            ResidentCheck.image = UIImage(named: "Check")
        } else {
            ResidentCheck.image = UIImage(named: "Fail")
        }
        
        if (User.USVisa) {
            USCheck.image = UIImage(named: "Check")
        } else {
            USCheck.image = UIImage(named: "Fail")
        }
        
        PhotoCheck.sd_setImage(with: storage.reference(forURL: User.Pic))
    }


}
