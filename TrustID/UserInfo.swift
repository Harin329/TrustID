//
//  UserInfo.swift
//  TrustID
//
//  Created by Harin Wu on 2020-02-02.
//  Copyright © 2020 TELUS. All rights reserved.
//

import Foundation
import Firebase

public struct UserInfo {
    var ID: String
    var FirstName: String
    var LastName: String
    var Citizen: String
    var Resident: String
    var USVisa: Bool
    var Birthday: Timestamp
    var Pic: String
}

// MARK: - init
extension UserInfo {
    init(ID: String, data: [String:Any]) {
        self.ID = ID
        self.FirstName = data["FirstName"] as? String ?? ""
        self.LastName = data["LastName"] as? String ?? ""
        self.Pic = data["PhotoURL"] as? String ?? ""
        self.Citizen = data["Citizenship"] as? String ?? ""
        self.Resident = data["Resident"] as? String ?? ""
        self.USVisa = data["USVisa"] as? Bool ?? false
        self.Birthday = data["Birthday"] as? Timestamp ?? Timestamp.init()
    }
}
