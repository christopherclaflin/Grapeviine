//
//  PostCell.swift
//  GrapeVines
//
//  Created by imac on 3/13/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation
import SDWebImage

protocol PostCellDelegate {
    func onLike(post: Post)
    func onReply(post: Post)
}
class PostCell: UITableViewCell {
    @IBOutlet weak var imgPoster: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var btnLike: UIButton!
    @IBOutlet weak var imgPost: FLAnimatedImageView!
    @IBOutlet weak var lblComment: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblReplies: UILabel!
    @IBOutlet weak var btnReply: UIButton!
    @IBOutlet weak var imgPostHeightConstraint: NSLayoutConstraint!
    
    var delegate : PostCellDelegate?
    
    private var post:Post?
    
    @IBAction func onLike(_ sender: Any) {
        
    }
    @IBAction func onReply(_ sender: Any) {
        if let post = self.post {
            delegate?.onReply(post: post)
        }
    }
    
    
    func setCellData (post: Post){
        self.post = post
        
        let type = post.type
        var canView = false
        var canLike = false
        var canReply = false

        if let currentLocation = Common.currentLocation {
            if post.canView(userLocation: currentLocation) {
                canView = true
            }
            
            if post.canLike(userLocation: currentLocation) {
                canLike = true
            }
            
            if post.canReply(userLocation: currentLocation) == .ok {
                canReply = true
            }
        } else {
            //checks only my posts
            
            if post.userID == Common.curUserID()! {
                canView = true
                canLike = true
                canReply = true
            }
        }
        
        
        //title
        if type == .photoBomb && !canView {
            self.lblTitle.text = ""
        } else {
            self.lblTitle.text = post.title
        }
        
        //type image
        switch type {
        case .post:
//            Common.setUserImage(imageView: self.imgPoster, userID: post.userID)
            self.imgPoster.image = UIImage.init(named: "ic_post_pin")
            break
        case .photoBomb:
            self.imgPoster.image = UIImage.init(named: "ic_photo_bomb")
            break
        case .grapeVine:
            self.imgPoster.image = UIImage.init(named: "ic_grape")
            break
        }
        
        //like button
        self.btnLike.isEnabled = canLike
        self.btnLike.setTitle(String(post.likesCount), for: .normal)
        
        //comment
        if canView {
            self.lblComment.text = post.text
        } else {
            if type == .photoBomb {
                self.lblComment.text = "You must be within 1/2 mile of this photobomb to view and comment on this photo"
            } else {
                self.lblComment.text = ""
            }
        }
        
        //content image
        if let imageURL = post.imageURL {
            if canView {
                Common.setFirebaseImage(imageView: self.imgPost, imageURL: imageURL)
                self.imgPostHeightConstraint.constant = 230
            } else {
                self.imgPostHeightConstraint.constant = 0
            }
        } else {
            self.imgPostHeightConstraint.constant = 0
        }

        
        //time
        self.lblTime.text = Common.timeDiffFromNow(time: post.time)
        
        //replies count
        let realReplies = post.repliesCount - 1
        if realReplies <= 1 {
            self.lblReplies.text = String(realReplies) + " reply"
        } else {
            self.lblReplies.text = String(realReplies) + " replies"
        }
        
        //reply
        self.btnReply.isEnabled = canReply
    }
}
