//
//  NotificationCell.swift
//  GrapeVines
//
//  Created by imac on 3/14/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation


class NotificationCell: UITableViewCell {
    private var notification: Notif?
    
    @IBOutlet weak var imgNotif: UIImageView!
    @IBOutlet weak var lblContent: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    
    func setCellData (notification: Notif){
        self.notification = notification
        
        let type = notification.type
        
        switch(type) {
        case .newGrapeVine:
            self.imgNotif.image = UIImage(named: "ic_grape")
            break
        case .newPhotoBomb:
            self.imgNotif.image = UIImage(named: "ic_photo_bomb")
            break
        default:
            self.imgNotif.image = nil
            break
        }
        
        self.lblContent.text = notification.content
        self.lblTime.text = Common.timeDiffFromNow(time: notification.time)
    }
}
