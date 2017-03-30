//
//  NotificationsViewController.swift
//  GrapeVines
//
//  Created by imac on 3/14/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Firebase
import Foundation

class NotificationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var table: UITableView!
    var _hNotificationAdd:FIRDatabaseHandle?, _hNotificationDelete:FIRDatabaseHandle?
    var notifications: NSMutableArray = []
    var _hNotifAdd:FIRDatabaseHandle?, _hNotifDelete:FIRDatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.delegate = self
        table.dataSource = self
        
        let trashButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearNotifications))
        self.navigationItem.rightBarButtonItem = trashButton
        
        _hNotifAdd = Common.ref.child(C.Path.notifications).child(Common.curUserID()!).observe(.childAdded, with: { (snapshot) in
            if snapshot.exists() {
                let notification = Notif(snapshot: snapshot)
                if notification.isValid() {
                    self.notifications.insert(notification, at: 0)
                    self.table.insertRows(at: [IndexPath.init(row: 0, section: 0)] , with: .automatic)
                
                    if self.navigationController?.tabBarController?.selectedIndex == 2 {
                    
                    
                        snapshot.ref.observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists() {
                                snapshot.ref.child("read").setValue("YES")
                            }
                        }, withCancel: { (error) in
                        
                        })
                    }
                }
            }
            
        })
        
        _hNotifDelete = Common.ref.child(C.Path.notifications).child(Common.curUserID()!).observe(.childRemoved, with: { (snapshot) in
            if snapshot.exists() {
                let n = self.notifications.count
                for i in 0..<n {
                    if(snapshot.key == (self.notifications[i] as! Notif).key) {
                        self.notifications.removeObject(at: i)
                        self.table.deleteRows(at: [IndexPath.init(row: i, section: 0)], with: .automatic)
                        break
                    }
                }
                
            }
        })

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let n = self.notifications.count
        
        for i in 0..<n {
            let notif = self.notifications[i] as! Notif

            if let key = notif.key {
                let ref = Common.ref.child(C.Path.notifications).child(Common.curUserID()!).child(key)
                
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        ref.child("read").setValue("YES")
                    }
                }, withCancel: { (error) in
                    
                })
                
            }
        }
    }
    
    @objc private func clearNotifications () {
        Common.ref.child(C.Path.notifications).child(Common.curUserID()!).removeValue();
    }
    
    deinit {
        
        if let hAdd = _hNotificationAdd {
            Common.ref.child(C.Path.notifications).child(Common.curUserID()!).removeObserver(withHandle: hAdd)
        }
        
        if let hDelete = _hNotificationDelete {
            Common.ref.child(C.Path.notifications).child(Common.curUserID()!).removeObserver(withHandle: hDelete)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notifications.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "notificationcell"
        let cell:NotificationCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! NotificationCell
        
        cell.tag = indexPath.row
        cell.selectionStyle = .none
        cell.accessoryType = .none
        
        let row = indexPath.row as Int
        cell.setCellData(notification: notifications[row] as! Notif)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row as Int
        let notification = notifications[row] as! Notif
        
        Common.ref.child(C.Path.posts).child(notification.postID!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.exists() {
                let post = Post(snapshot: snapshot)
                
                Common.pushCommentViewController(post: post, vc: self)
            }
        })
    }
    
    
}
