//
//  SettingsViewController.swift
//  GrapeVines
//
//  Created by imac on 3/12/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var swLike: UISwitch!
    @IBOutlet weak var swComment: UISwitch!
    @IBOutlet weak var swGrapeVines: UISwitch!
    @IBOutlet weak var swPhotoBomb: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ref = Common.ref.child(C.Path.settings).child(Common.curUserID()!)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()) {
                if let settings = snapshot.value as? [String:AnyObject] {
                    if let _ = settings[C.SettingsFields.likes] as? String {
                        self.swLike.setOn(true, animated: false)
                    } else {
                        self.swLike.setOn(false, animated: false)
                    }
                    
                    if let _ = settings[C.SettingsFields.comments] as? String {
                        self.swComment.setOn(true, animated: false)
                    } else {
                        self.swComment.setOn(false, animated: false)
                    }
                    
                    if let _ = settings[C.SettingsFields.photoBombs] as? String {
                        self.swPhotoBomb.setOn(true, animated: false)
                    } else {
                        self.swPhotoBomb.setOn(false, animated: false)
                    }
                    
                    if let _ = settings[C.SettingsFields.grapeVines] as? String {
                        self.swGrapeVines.setOn(true, animated: false)
                    } else {
                        self.swGrapeVines.setOn(false, animated: false)
                    }
                }
            }
        })
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 1:
            if row == 0 {
                //report a problem
                Common.openURL(linkURL: C.Link.report)
            }
        case 2:
            if row == 0 {
                //blog
                Common.openURL(linkURL: C.Link.blog)
            } else if row == 1 {
                //privacy
                Common.openURL(linkURL: C.Link.privacy)
            } else if row == 2{
                //terms
                Common.openURL(linkURL: C.Link.terms)
            } else {
                //logout
                
                let firebaseAuth = FIRAuth.auth()
                do {
                    try firebaseAuth?.signOut()
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.window?.rootViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateInitialViewController()
                    
                } catch let signOutError as NSError {
                    Common.alert(title: "Log out", message: signOutError.localizedDescription, viewController: self)
                }
            }
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    @IBAction func onLikeChange(_ sender: Any) {
        Common.switchNotificationSetting(name: C.SettingsFields.likes, isOn: swLike.isOn)
    }
    
    @IBAction func onCommentChange(_ sender: Any) {
        Common.switchNotificationSetting(name: C.SettingsFields.comments, isOn: swComment.isOn)
    }
    
    @IBAction func onGrapeVineChange(_ sender: Any) {
        Common.switchNotificationSetting(name: C.SettingsFields.grapeVines, isOn: swGrapeVines.isOn)
    }
    
    @IBAction func onPhotoBombChange(_ sender: Any) {
        Common.switchNotificationSetting(name: C.SettingsFields.photoBombs, isOn: swPhotoBomb.isOn)
    }
    
}
