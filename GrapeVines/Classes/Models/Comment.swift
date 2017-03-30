//
//  Comment.swift
//  GrapeVines
//
//  Created by imac on 3/18/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation
import Firebase

class Comment {
    internal let postID: String
    internal let userID: String
    internal let title: String?
    internal let text: String?
    internal let time: Double
    internal let imageURL: String?
    internal let key:String?
    
    internal var likesCount:Int = 0
    internal var iLike:Bool = false
    
    internal var post: Post?
    
    init(postID: String, userID: String, title:String?, text: String?, time: Double, imageURL: String?) {
        self.postID = postID
        self.userID = userID
        self.title = title
        self.text = text
        self.time = time
        self.imageURL = imageURL
        self.key = nil
    }
    
    init(snapshot: FIRDataSnapshot, post: Post) {
        let commentInfo = snapshot.value! as! NSDictionary
        
        self.postID = commentInfo[C.CommentFields.postID] as! String
        self.userID = commentInfo[C.CommentFields.userID] as! String
        self.title = commentInfo[C.CommentFields.title] as? String
        self.text = commentInfo[C.CommentFields.text] as? String
        self.time = commentInfo[C.CommentFields.time] as! Double
        self.imageURL = commentInfo[C.CommentFields.imageURL] as? String
        
        self.key = snapshot.key
        
        self.post = post
        
        if let likes = commentInfo[C.CommentFields.likes] {
            if let likeDic = likes as? Dictionary<String, String> {
                self.likesCount = likeDic.count
                if let _ = likeDic.index(forKey: Common.curUserID()!) {
                    self.iLike = true
                } else {
                    self.iLike = false
                }
            }
        }
    }
    
    func comment(completionHandler:@escaping(Error?)->()) {
        let commentInfo :NSMutableDictionary = NSMutableDictionary.init()
        commentInfo[C.CommentFields.postID] = self.postID
        commentInfo[C.CommentFields.userID] = Common.curUserID()!
        commentInfo[C.CommentFields.title] = self.title
        commentInfo[C.CommentFields.text] = self.text
        commentInfo[C.CommentFields.time] = FIRServerValue.timestamp()
        commentInfo[C.CommentFields.imageURL] = self.imageURL
        
        let ref = Common.ref.child(C.Path.comments).child(self.postID).childByAutoId()
        ref.setValue(commentInfo) { (error, ref) in
            
            if let post = self.post {
                let text = self.text ?? ""
                Common.sendNotificationForCommentPost(userID: post.userID, postID: self.postID, comment: text)
            }
            
            completionHandler(error)
            
            if let post = self.post {
                if post.type == .grapeVine {
                    Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.grapeVines)
                        .child(post.key!).setValue("YES")
                }
            }            
        }
    }
    
    func doLike () {
        if iLike {
            Common.ref.child(C.Path.comments).child(self.postID).child(self.key!)
                .child(C.CommentFields.likes).child(Common.curUserID()!).removeValue();
            iLike = false
            
        } else {
            Common.ref.child(C.Path.comments).child(self.postID).child(self.key!)
                .child(C.CommentFields.likes).child(Common.curUserID()!).setValue("YES");
            iLike = true
            if let post = self.post {
                let comment = self.text ?? ""
                Common.sendNotificationForLikeComment(userID: post.userID, postID: postID, comment: comment)
            }
        }
    }
}
