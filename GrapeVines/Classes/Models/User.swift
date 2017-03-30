//
//  User.swift
//  GrapeVines
//
//  Created by imac on 3/12/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation
import Firebase

internal class User {
    internal let userID: String
    internal let displayName: String?
    internal let photoURL: String?
    internal let bio: String?
    
    init(userID: String, displayName: String, photoURL: String, bio: String?) {
        self.userID = userID
        self.displayName = displayName
        self.photoURL = photoURL
        self.bio = bio
    }
    
    init(snapshot: FIRDataSnapshot) {
        let userInfo = snapshot.value! as! NSDictionary
        
        self.userID = snapshot.key
        self.displayName = userInfo[C.UserFields.displayName] as? String
        self.photoURL = userInfo[C.UserFields.photoURL] as? String
        self.bio = userInfo[C.UserFields.bio] as? String
    }
}
