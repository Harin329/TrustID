//
//  AppDelegate.swift
//  TrustID
//
//  Created by Harin Wu on 2020-02-01.
//  Copyright © 2020 TELUS. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FirebaseAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
      -> Bool {
      return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
      // ...
      if let error = error {
        // ...
        return
      }

      guard let authentication = user.authentication else { return }
      let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                        accessToken: authentication.accessToken)
        
        if Auth.auth().currentUser != nil {
            do {
                print("running http")
                let newDict =
                    [
                        "email": Auth.auth().currentUser?.email!
                    ]
                let jsonData = try JSONSerialization.data(withJSONObject: newDict)
                
                print(String(decoding: jsonData, as: UTF8.self))
                
                //API Call
                let url = URL(string: "https://thacks-api.herokuapp.com/config")!
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.httpBody = jsonData
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                URLSession.shared.getAllTasks { (openTasks: [URLSessionTask]) in
                    NSLog("open tasks: \(openTasks)")
                }
                
                let task = URLSession.shared.dataTask(with: request, completionHandler: { (responseData: Data?, response: URLResponse?, error: Error?) in
                    NSLog("\(response)")
                    DispatchQueue.main.async {
                        print(String(decoding: responseData!, as: UTF8.self))
                        dataPacket = responseData!
                    }
                })
                task.resume()
                
                
                
            } catch {
                print(error.localizedDescription)
            }
        } else {
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                  // ...
                  return
                }
                
                do {
                    print("running http")
                    let newDict =
                        [
                            "email": Auth.auth().currentUser?.email!
                        ]
                    let jsonData = try JSONSerialization.data(withJSONObject: newDict)
                    
                    print(String(decoding: jsonData, as: UTF8.self))
                    
                    //API Call
                    let url = URL(string: "https://thacks-api.herokuapp.com/config")!
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = jsonData
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    URLSession.shared.getAllTasks { (openTasks: [URLSessionTask]) in
                        NSLog("open tasks: \(openTasks)")
                    }
                    
                    let task = URLSession.shared.dataTask(with: request, completionHandler: { (responseData: Data?, response: URLResponse?, error: Error?) in
                        NSLog("\(response)")
                        DispatchQueue.main.async {
                            print(String(decoding: responseData!, as: UTF8.self))
                            dataPacket = responseData!
                        }
                    })
                    task.resume()
                    
                    
                    
                } catch {
                    print(error.localizedDescription)
                }
            
              }
        }
        
      
    }

    
    


}

