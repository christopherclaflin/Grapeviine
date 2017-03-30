//
//  CommentCell.swift
//  GrapeVines
//
//  Created by imac on 3/13/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation
import SDWebImage

protocol CommentCellDelegate {
    func onLike(like: Bool)
}

class CommentCell: UITableViewCell {
    @IBOutlet weak var btnLike: UIButton!
    @IBOutlet weak var lblComment: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var imgPost: FLAnimatedImageView!
    @IBOutlet weak var imgPostTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgPostHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgPoster: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblTitleHeightConstraint: NSLayoutConstraint!
    
    var comment: Comment?
    var cellType: C.CommentCellType = .comment
    var postType: C.PostType = .post
    var delegate: CommentCellDelegate?
    
    @IBAction func onLike(_ sender: Any) {
        if let comment = self.comment {
            comment.doLike()
            //self.btnLike.setTitle(String(comment.likes), for: .normal)
            
            //delegate?.onLike(like: comment.iLike)
        }

    }
    
    func setCellData (comment: Comment){
        self.comment = comment
        
        //imgPoster
        if self.cellType == .header {
            switch self.postType {
            case .post:
                self.imgPoster.image = nil
                break
            case .photoBomb:
                self.imgPoster.image = UIImage(named: "ic_photo_bomb")
                break
            case .grapeVine:
                self.imgPoster.image = UIImage(named: "ic_grape")
                break
            }
        } else {
            self.imgPoster.image = nil
        }
        
        // title
        
        if self.cellType == .header {
            if let title = comment.title {
                self.lblTitle.text = title
            } else {
                self.lblTitle.text = ""
            }
            self.lblTitleHeightConstraint.constant = 23
        } else {
            self.lblTitleHeightConstraint.constant = 0
        }
        
        
        //like button
        self.btnLike.setTitle(String(comment.likesCount), for: .normal)
        
        //comment
        self.lblComment.text = comment.text
        
        
        //content image
        if let imageURL = comment.imageURL {
            Common.setFirebaseImage(imageView: self.imgPost, imageURL: imageURL)
            self.imgPostTopConstraint.constant = 12
            self.imgPostHeightConstraint.constant = 230
        } else {
            self.imgPostTopConstraint.constant = 0
            self.imgPostHeightConstraint.constant = 0
        }
        
        //time
        self.lblTime.text = Common.timeDiffFromNow(time: comment.time)
    }

}
