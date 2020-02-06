//
//  IDViewController.swift
//  TrustID
//
//  Created by Harin Wu on 2020-02-04.
//  Copyright © 2020 TELUS. All rights reserved.
//

import UIKit
import CoreNFC

class IDViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    @IBAction func Register(_ sender: Any) {
        guard NFCTagReaderSession.readingAvailable else {
            print("Not Supported")
            return
        }
        // 1
        //Compass Card uses 14443
        let session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self, queue: nil)
        // 2
        session!.alertMessage = "Hold your device near a tag to scan it."
        // 3
        session!.begin()
    }
    
    @IBAction func SendBluetooth(_ sender: Any) {
    }
    
    @IBAction func ReceiveBluetooth(_ sender: Any) {
    }
    

}

extension IDViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("Started scanning for tags")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("Session did invalidate with error: \(error)")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print(tags)
        if (!tags.isEmpty) {
            session.invalidate()
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Tag Found", message: "\(tags[0])", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                NSLog("A Tag Was Found")
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

}
