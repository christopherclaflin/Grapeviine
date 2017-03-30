//
//  Common.swift
//  GrapeVines
//
//  Created by imac on 3/12/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import DateToolsSwift
import Foundation
import Firebase
import GeoFire
import SDWebImage

class Common {
    static var timeOffset: Double = 0
    static var currentLocation: CLLocation?
    static var grapeVines : NSMutableArray = NSMutableArray.init()
    static var unreadNotifications : Int = 0
    static var currentAddress : String?

    
    static var ref: FIRDatabaseReference {
        get {
            return FIRDatabase.database().reference()
        }
    }
    
    static var sref: FIRStorageReference {
        get {
            return FIRStorage.storage().reference()
        }
    }
    
    static var geoFireForPost: GeoFire {
        get {
            return GeoFire(firebaseRef: Common.ref.child("post locations"))
        }
    }
    
    static var geoFireForUser: GeoFire {
        get {
            return GeoFire(firebaseRef: Common.ref.child("user locations"))
        }
    }
    
    //MARK: shared singleton
    
    static let shared : Common =  {
        let instance = Common()
        return instance
    }()
    
    
    static func hasGrapeVines(postID: String) -> Bool {
        for i in 0 ..< grapeVines.count {
            if(postID == (grapeVines[i] as! String)) {
                return true
            }
            
        }
        
        return false
    }
    
    private init() {        
    }
    
    static func curUserID () -> String? {
        return FIRAuth.auth()?.currentUser?.uid
    }
    
    static func curUser () -> (displayName:String?, photoURL:String?, userID:String?) {
        let user = FIRAuth.auth()?.currentUser
        return (user?.displayName, user?.photoURL?.absoluteString, user?.uid)
    }
    
    static func setUserImage( imageView: UIImageView, userID: String) {
        Common.ref.child(C.Path.users).child(userID).observeSingleEvent(of: .value, with: {
            (snapshot) in
            if snapshot.exists() {
                let user = User(snapshot:snapshot)
                
                Common.setFirebaseImage(imageView: imageView, imageURL: user.photoURL)
            } else {
                imageView.image = UIImage.init(named: "ic_profile")
            }
        })
    }
    
    static func setFirebaseImage(imageView: UIImageView, imageURL:String?) {
        if let imageURL = imageURL {
            if imageURL.contains("gs://") {
                FIRStorage.storage().reference(forURL: imageURL).downloadURL(completion: { (url, error) in
                    if let url = url {
                        imageView.sd_setImage(with: url)
                    }
                })
            } else {
                imageView.sd_setImage(with: URL.init(string: imageURL))
            }
        }
    }
    
    static func timestamp () -> String {
        return "\(NSDate().timeIntervalSince1970*1000)"
    }
    
    static func alert(title:String, message:String, viewController:UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    static func subscribeToAll() {
        Common.switchNotificationSetting(name: C.SettingsFields.likes, isOn: true)
        Common.switchNotificationSetting(name: C.SettingsFields.comments, isOn: true)
        Common.switchNotificationSetting(name: C.SettingsFields.grapeVines, isOn: true)
        Common.switchNotificationSetting(name: C.SettingsFields.photoBombs, isOn: true)
    }

    static func timeDiffFromNow(time: TimeInterval)->String {
        let date = Date.init(timeIntervalSince1970: time/1000)
        
        return date.shortTimeAgoSinceNow
    }
    
    static func switchNotificationSetting(name: String, isOn:Bool) {
        let ref = Common.ref.child(C.Path.settings).child(Common.curUserID()!).child(name)
        
        //subscribe to notification
        let topic = "/topics/user-\(Common.curUserID()!)-\(name)"
        
        if isOn {
            ref.setValue("YES")
            FIRMessaging.messaging().subscribe(toTopic: topic)
        } else {
            ref.setValue(nil)
            FIRMessaging.messaging().unsubscribe(fromTopic: topic)
        }
    }
    
    static func openURL(linkURL:String) {
        let url = URL(string: linkURL)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    
    static func sendNotificationForLikeComment(userID: String, postID: String, comment: String) {
        if userID == Common.curUserID()! {
            return
        }
        
        let content = "Someone liked your comment, \"\(comment)\""
        
        let notif = Notif.init(type: .likeComment, userID: userID, postID: postID, content: content)
        notif.commit()
    }
    
    static func sendNotificationForCommentPost(userID: String, postID: String, comment: String) {
        if userID == Common.curUserID()! {
            return
        }
        
        let content = "Someone commented on your post, \"\(comment)\""

        let notif = Notif.init(type: .commentPost, userID: userID, postID: postID, content: content)
        notif.commit()
    }
    
    static func sendNotificationForPhotoBomb(userID: String, postID: String) {
        if userID == Common.curUserID()! {
            return
        }
        
        let content = "A photo bomb is near you"
        
        let notif = Notif.init(type: .newPhotoBomb, userID: userID, postID: postID, content: content)
        notif.commit()
    }
    
    static func sendNotificationForGrapeVine(userID: String, postID: String, title: String) {
        if userID == Common.curUserID()! {
            return
        }
        
        let content = "You passed through the [\(title)] grape vine! Join the conversation!"
        
        let notif = Notif.init(type: .newGrapeVine, userID: userID, postID: postID, content: content)
        notif.commit()
    }
    
    static func doPost (url: String, parameters: [String: Any]) {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }
        task.resume()
    }
    
   
//    static func sendPushNotification(topic: String, userID: String, title: String, body: String) {
//        let url = "http://thesuperdevs.com/grapevines/public/send-to-topic"
//        let params = ["topic": topic, "title": title, "body": body]
//
//        Common.doPost(url: url, parameters: params)
//    }
 
    static func pushCommentViewController(post:Post, vc:UIViewController) {
        if post.blockedMe {
            Common.alert(title: post.title ?? "", message: "Poster blocked from this conversation", viewController: vc)
        } else {
            let reply = post.canReply(userLocation: Common.currentLocation)
            if reply == .ok {
                if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "comment") as? CommentViewController {
                    viewController.post = post
                    if let navigator = vc.navigationController {
                        navigator.pushViewController(viewController, animated: true)
                    }
                }
            } else if reply == .outOfRange {
                Common.alert(title: post.title ?? "", message: "You are too far away to view this post.", viewController: vc)
            } else {
                Common.alert(title: post.title ?? "", message: "You are not able to join this post.", viewController: vc)
            }
        }
    }
    
}
