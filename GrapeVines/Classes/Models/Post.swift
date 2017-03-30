//
//  Post.swift
//  GrapeVines
//
//  Created by imac on 3/13/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation
import Firebase
import GeoFire
import GoogleMaps

internal class Post {
    internal let userID: String
    internal let type: C.PostType
    internal let title: String?
    internal let text: String?
    internal let time: Double
    internal let imageURL: String?
    internal let longitude: Double
    internal let latitude: Double
    internal let radius: Double
    internal let key:String?
    
    
    internal var likesCount:Int = 0
    internal var repliesCount:Int = 0
    
    internal var blockedMe:Bool = false
    internal var passedThroughMe: Bool = false
    
    var marker: GMSMarker?
    
    init(userID: String, type: C.PostType, title: String?, text: String?, time: Double, longitude: Double, latitude: Double, radius: Double, imageURL: String?) {
        self.userID = userID
        self.type = type
        self.title = title
        self.text = text
        self.time = time
        self.longitude = longitude
        self.latitude = latitude
        self.radius = radius
        self.imageURL = imageURL
        
        self.key = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        let postInfo = snapshot.value! as! NSDictionary
        
        self.userID = postInfo[C.PostFields.userID] as! String
        self.type = C.PostType(rawValue: postInfo[C.PostFields.type] as! String)!
        self.title = postInfo[C.PostFields.title] as? String
        self.text = postInfo[C.PostFields.text] as? String
        self.time = postInfo[C.PostFields.time] as! Double
        self.longitude = postInfo[C.PostFields.longitude] as! Double
        self.latitude = postInfo[C.PostFields.latitude] as! Double
        self.radius = postInfo[C.PostFields.radius] as! Double
        self.imageURL = postInfo[C.PostFields.imageURL] as? String
        self.likesCount = postInfo[C.PostFields.likesCount] as? Int ?? 0
        self.repliesCount = postInfo[C.PostFields.repliesCount] as? Int ?? 0
        
        self.key = snapshot.key
        
        if let blocks = postInfo[C.PostFields.blocks] {
            if let blockDic = blocks as? Dictionary<String, String> {
                if let _ = blockDic.index(forKey: Common.curUserID()!) {
                    self.blockedMe = true
                } else {
                    self.blockedMe = false
                }
            }
        }
        
        if let passes = postInfo[C.PostFields.passes] {
            if let passDic = passes as? Dictionary<String, String> {
                if let _ = passDic.index(forKey: Common.curUserID()!) {
                    self.passedThroughMe = true
                } else {
                    self.passedThroughMe = false
                }
            }
        }
    }
    
    func post(completionHandler:@escaping(Error?)->()) {
        let postInfo :NSMutableDictionary = NSMutableDictionary.init()
        postInfo[C.PostFields.userID] = Common.curUserID()
        postInfo[C.PostFields.title] = title
        postInfo[C.PostFields.text] = text
        postInfo[C.PostFields.type] = self.type.rawValue
        postInfo[C.PostFields.latitude] = NSNumber.init(value: self.latitude)
        postInfo[C.PostFields.longitude] = NSNumber.init(value: self.longitude)
        postInfo[C.PostFields.radius] = NSNumber.init(value: radius)
        postInfo[C.PostFields.time] = FIRServerValue.timestamp()
        postInfo[C.PostFields.imageURL] = imageURL
        
        let ref = Common.ref.child(C.Path.posts).childByAutoId()
        
        ref.setValue(postInfo) { (error, ref) in
            let newPostKey = ref.key
            
            //save post link to user node
            Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.posts).child(newPostKey).setValue("YES")
            
            //save location 
            Common.geoFireForPost.setLocation(CLLocation.init(latitude: self.latitude, longitude: self.longitude) , forKey: ref.key, withCompletionBlock: { (error) in
                if let error = error {
                    completionHandler(error)
                } else {
                
                    switch(self.type) {
                    case .post:
                        let comment = Comment.init(postID: ref.key, userID: self.userID, title: nil, text: self.text, time: 0, imageURL: self.imageURL)
                        comment.comment(completionHandler: { (error) in
                            completionHandler(error)
                        })
                        break
                    case .photoBomb:
                        let address = Common.currentAddress ?? ""
                        let comment = Comment.init(postID: ref.key, userID: self.userID, title: address, text: self.text, time: 0, imageURL: self.imageURL)
                        comment.comment(completionHandler: { (error) in
                            completionHandler(error)
                            
                            //send notification to users nearby
                            let location = Common.currentLocation
                            let radiusInKM = self.radius * C.kilometerPerMile
                            let circleQuery = Common.geoFireForUser.query(at: location, withRadius: radiusInKM)
                            
                            circleQuery?.observeReady({ 
                                circleQuery?.observe(.keyEntered, with: { (key, location) in
                                    if let key = key {
                                        print("notifying " + key + " for new photo bomb")
                                        Common.sendNotificationForPhotoBomb(userID: key, postID: newPostKey)
                                    }
                                })
                            })
                        })
                        break
                    case .grapeVine:
                        let comment = Comment.init(postID: ref.key, userID: self.userID, title: self.title, text: self.text, time: 0, imageURL: self.imageURL)
                        comment.comment(completionHandler: { (error) in
                            completionHandler(error)
                            //register to my grapevines
                            Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.grapeVines).child(ref.key).setValue("YES")
                            
                            //send notification to users nearby
                            let location = Common.currentLocation
                            let radiusInKM = self.radius * C.kilometerPerMile
                            let circleQuery = Common.geoFireForUser.query(at: location, withRadius: radiusInKM)
                            
                            var text: String?
                            if self.title != nil {
                                text = self.title
                            } else {
                                text = self.text
                            }
                            circleQuery?.observeReady({
                                circleQuery?.observe(.keyEntered, with: { (key, location) in
                                    if let key = key {
                                        Common.sendNotificationForGrapeVine(userID: key, postID: newPostKey, title: text!)
                                        Common.ref.child(C.Path.posts).child(ref.key).child(C.PostFields.passes).child(key).setValue("YES")
                                    }
                                })
                            })
                        })
                        
                        
                        break
                    }
                }
            })
        }
    }
    
    private func notifyUsers () {
        
    }
    
    func canView(userLocation:CLLocation)->Bool {
        // if poster is me, can view anytime anywhere
        if self.userID == Common.curUserID()! {
            return true
        }
        
        let postLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        switch self.type {
        case .post:
            return true
        case .photoBomb:
            if postLocation.distance(from: userLocation) <= 0.5 * C.meterPerMile {
                return true
            } else {
                return false
            }
        case .grapeVine:
            return true
        }
    }
    
    func canLike(userLocation:CLLocation)->Bool {
        // if poster is me, can like anytime anywhere
        if self.userID == Common.curUserID()! {
            return true
        }
        
        let postLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        switch self.type {
        case .post:
            return true
        case .photoBomb:
            if postLocation.distance(from: userLocation) <= 0.5 * C.meterPerMile {
                return true
            } else {
                return false
            }
        case .grapeVine:
            return true
        }
    }
    
    func canReply(userLocation:CLLocation?)-> C.ReplyErrorType {
        // if poster is me, can reply anytime anywhere
        if self.userID == Common.curUserID()! {
            return .ok
        }
        
        if let userLocation = userLocation {
        
            let postLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
            
            
            switch self.type {
            case .post:
                if postLocation.distance(from: userLocation) <= self.radius * C.meterPerMile {
                    return .ok
                } else {
                    return .outOfRange
                }
            case .photoBomb:
                if postLocation.distance(from: userLocation) <= 0.5 * C.meterPerMile {
                    return .ok
                } else {
                    return .outOfRange
                }
            case .grapeVine:
                if Common.hasGrapeVines(postID: self.key!) {
                    return .ok
                }
                
                let postTime = self.time
                let date = Date.init(timeIntervalSince1970: postTime/1000)
                print(date.timeIntervalSinceNow)
                
                let diff = abs(date.timeIntervalSinceNow)
                if diff / 60 / 60 <= 6 {
                    if self.passedThroughMe || postLocation.distance(from: userLocation) <= self.radius * C.meterPerMile {
                        return .ok
                    } else {
                        return .outOfRange
                    }
                } else {
                    return .closed
                }
                
            }
        } else {
            return .outOfRange
        }
    }
    
    func doLike () {
        
    }
    
    func blockUser(userID: String) {
        if let key = self.key {
            if self.userID == userID {
                return
            }
            
            Common.ref.child(C.Path.posts).child(key).child(C.PostFields.blocks)
                .child(userID).setValue("YES")
        }
    }
}
