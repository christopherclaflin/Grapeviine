//
//  Notification.swift
//  GrapeVines
//
//  Created by imac on 3/20/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Firebase
import Foundation

class Notif {
    internal let type: C.NotificationType
    internal let userID: String?
    internal let postID: String?
    internal let content: String?
    internal let time: Double
    
    internal let key: String?
    
    init(type: C.NotificationType, userID: String, postID: String, content: String) {
        self.type = type
        self.userID = userID
        self.postID = postID
        self.content = content
        self.time = 0
        
        key = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        let notifInfo = snapshot.value! as! NSDictionary
        self.userID = notifInfo[C.NotificationFields.userID] as? String
        self.postID = notifInfo[C.NotificationFields.postID] as? String
        self.content = notifInfo[C.NotificationFields.content] as? String
        if let rawType = notifInfo[C.NotificationFields.type] as? String{
            self.type = C.NotificationType(rawValue: rawType)!
        } else {
            self.type = .commentPost
        }
        
        self.time = notifInfo[C.NotificationFields.time] as? Double ?? 0
        self.key = snapshot.key
    }
    
    func isValid() -> Bool {
        if let _ = self.key {
            if let _ = self.userID {
                if let _ = self.postID {
                    return true
                }
            }
        }
        
        return false
    }
    
    func commit() {
        let notificationInfo = ["userID": userID!, "postID": postID!, "content": content ?? "", "type": type.rawValue, "time": FIRServerValue.timestamp()] as [String : Any]
        Common.ref.child(C.Path.notifications).child(userID!).childByAutoId().setValue(notificationInfo)
    }
}
