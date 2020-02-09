//
//  IDViewController.swift
//  TrustID
//
//  Created by Harin Wu on 2020-02-04.
//  Copyright © 2020 TELUS. All rights reserved.
//

import UIKit
import CoreNFC
import CoreBluetooth
import os
import LocalAuthentication
import GoogleSignIn
import FirebaseAuth

class IDViewController: UIViewController  {
    
    var peripheralManager: CBPeripheralManager!
    var connectedCentral: CBCentral?
    var transferCharacteristic: CBCharacteristic?
    var dataToSend = Data()
    var sendDataIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
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
    
    @IBAction func Gate(_ sender: Any) {
        self.performSegue(withIdentifier: "GateOpen", sender: nil)
    }
    
    @IBAction func Logout(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            GIDSignIn.sharedInstance()?.signOut()
            print("Logged Out")
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    //Peripheral
    static var sendingEOM = false
    
    private func sendData() {
        
        guard let transferCharacteristic = transferCharacteristic else {
            return
        }
        
        // First up, check if we're meant to be sending an EOM
        if IDViewController.sendingEOM {
            // send it
            let didSend = peripheralManager.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic as! CBMutableCharacteristic, onSubscribedCentrals: nil)
            // Did it send?
            if didSend {
                // It did, so mark it as sent
                IDViewController.sendingEOM = false
                os_log("Sent: EOM")
            }
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // We're not sending an EOM, so we're sending data
        // Is there any left to send?
        if sendDataIndex >= dataToSend.count {
            // No data left.  Do nothing
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        var didSend = true
        while didSend {
            
            // Work out how big it should be
            var amountToSend = dataToSend.count - sendDataIndex
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            // Copy out the data we want
            let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            
            // Send it
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic as! CBMutableCharacteristic, onSubscribedCentrals: nil)
            
            // If it didn't work, drop out and wait for the callback
            if !didSend {
                return
            }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            os_log("Sent %d bytes: %s", chunk.count, String(describing: stringFromData))
            
            // It did send, so update our index
            sendDataIndex += amountToSend
            // Was it the last one?
            if sendDataIndex >= dataToSend.count {
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                IDViewController.sendingEOM = true
                
                //Send it
                let eomSent = peripheralManager.updateValue("EOM".data(using: .utf8)!,
                                                            for: transferCharacteristic as! CBMutableCharacteristic, onSubscribedCentrals: nil)
                
                if eomSent {
                    // It sent; we're all done
                    IDViewController.sendingEOM = false
                    os_log("Sent: EOM")
                }
                return
            }
        }
    }

    private func setupPeripheral() {
        
        // Build our service.
        
        // Start with the CBMutableCharacteristic.
        let transferCharacteristic = CBMutableCharacteristic(type: InfoSent.characteristicUUID,
                                                         properties: [.notify, .writeWithoutResponse],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: InfoSent.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
        
        // Save the characteristic for later.
        self.transferCharacteristic = transferCharacteristic

    }
    
    @IBAction func SendBluetooth(_ sender: Any) {
        let context = LAContext()
        context.localizedCancelTitle = "Use FaceID/TouchID"
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            let reason = "Open Door"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in

                if success {
                    // Move to the main thread because a state update triggers UI changes.
                    DispatchQueue.main.async { [unowned self] in
                        if !self.peripheralManager.isAdvertising {
                            self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [InfoSent.serviceUUID]])
                            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in
                                self.peripheralManager.stopAdvertising()
                            }
                        } else {
                            self.peripheralManager.stopAdvertising()
                        }
                    }

                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")
                    // Fall back to a asking for username and password.
                }
            }
            
        }
    }
    

}

extension IDViewController: CBPeripheralManagerDelegate {
    // implementations of the CBPeripheralManagerDelegate methods

    /*
     *  Required protocol method.  A full app should take care of all the possible states,
     *  but we're just waiting for to know when the CBPeripheralManager is ready
     *
     *  Starting from iOS 13.0, if the state is CBManagerStateUnauthorized, you
     *  are also required to check for the authorization state of the peripheral to ensure that
     *  your app is allowed to use bluetooth
     */
    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        if (peripheral.state == .poweredOn) {
            
        } else {
            peripheralManager.stopAdvertising()
        }
        
        switch peripheral.state {
        case .poweredOn:
            // ... so start working with the peripheral
            os_log("CBManager is powered on")
            setupPeripheral()
        case .poweredOff:
            os_log("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            os_log("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            if #available(iOS 13.0, *) {
                switch peripheral.authorization {
                case .denied:
                    os_log("You are not authorized to use Bluetooth")
                case .restricted:
                    os_log("Bluetooth is restricted")
                default:
                    os_log("Unexpected authorization")
                }
            } else {
                // Fallback on earlier versions
            }
            return
        case .unknown:
            os_log("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            os_log("A previously unknown peripheral manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }

    /*
     *  Catch when someone subscribes to our characteristic, then start sending them data
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        os_log("Central subscribed to characteristic")
        
        //Not using hardcoded
        /*let tid = "t947107"
        let token = "token1"
         
         let dict =
         [
         "tid": tid,
         "token": token
         ]*/
        //let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        
        // Get the data
        dataToSend = dataPacket
        
        // Reset the index
        sendDataIndex = 0
        
        // save central
        connectedCentral = central
        
        // Start sending
        sendData()
        
    }
    
    /*
     *  Recognize when the central unsubscribes
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        os_log("Central unsubscribed from characteristic")
        connectedCentral = nil
    }
    
    /*
     *  This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        sendData()
    }
    
    /*
     * This callback comes in when the PeripheralManager received write to characteristics
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for aRequest in requests {
            guard let requestValue = aRequest.value,
                let stringFromData = String(data: requestValue, encoding: .utf8) else {
                    continue
            }
            
            os_log("Received write request of %d bytes: %s", requestValue.count, stringFromData)
            print(stringFromData)
        }
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
