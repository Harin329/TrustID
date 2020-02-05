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
    @IBOutlet weak var RegisterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    @IBAction func Register(_ sender: Any) {
        guard NFCReaderSession.readingAvailable else {
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
    

}

extension IDViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("Started scanning for tags")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("Session did invalidate with error: \(error)")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        //RegisterButton.setTitle("\(tags[0])", for: .normal)
        print(tags)
    }

}
