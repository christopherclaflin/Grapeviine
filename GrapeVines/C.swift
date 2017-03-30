//
//  Constants.swift
//  GrapeVines
//
//  Created by imac on 3/11/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation


struct C {
    static let meterPerMile = 1609.344
    static let kilometerPerMile = 1.609344
    
    struct Segues {
        static let loginToSignup = "LoginToSignup"
        static let loginToHome = "LoginToHome"
        static let signupToHome = "SignupToHome"
    }
    
    enum PostType : String {
        case post = "post"
        case photoBomb = "photoBomb"
        case grapeVine = "grapeVine"
    }
    
    enum ReplyErrorType : Int {
        case ok =  0
        case closed = 1
        case outOfRange = 2
    }
    
    enum CommentCellType : Int {
        case header = 1
        case comment = 2
    }
    
    enum NotificationType : String {
        case likeComment = "lc"
        case commentPost = "cp"
        case postInGrapeVine = "pg"
        case newPhotoBomb = "np"
        case newGrapeVine = "ng"
    }
    
    struct Path {
        static let likes = "likes"
        static let posts = "posts"
        static let comments = "comments"
        static let settings = "settings"
        static let users = "users"
        static let notifications = "notifications"
        static let unread = "unreads"
    }
    
    struct UserFields {
        static let displayName = "displayName" //not used
        static let photoURL = "photoURL" //not used
        static let bio = "bio" //not used
        static let posts = "posts"
        static let grapeVines = "grapeVines"
        static let deviceToken = "deviceToken"
    }
    
    struct NotificationFields {
        static let type = "type"
        static let userID = "userID"
        static let postID = "postID"
        static let content = "content"
        static let time = "time"
        static let read = "read"
    }
    
    struct PostFields {
        static let userID = "userID"
        static let type = "type"
        static let title = "title"
        static let text = "text"
        static let time = "time"
        static let imageURL = "imageURL"
        static let longitude = "longitude"
        static let latitude = "latitude"
        static let radius = "radius"
        static let blocks = "blocks"
        static let passes = "passes"
        static let likesCount = "likesCount"
        static let repliesCount = "repliesCount"
    }
    
    struct CommentFields {
        static let postID = "postID"
        static let userID = "userID"
        static let title = "title"
        static let text = "text"
        static let imageURL = "imageURL"
        static let time = "time"
        static let likes = "likes"
        static let likesCount = "likesCount"
    }
    
    struct SettingsFields {
        static let likes = "likes"
        static let comments = "comments"
        static let grapeVines = "grapeVines"
        static let photoBombs = "photoBombs"
    }

    struct Link{
        static let report = "https://grapeviineapp.com/contact"
        static let blog = "https://grapeviineapp.com/blog"
        static let privacy = "https://grapeviineapp.com/privacy"
        static let terms = "https://grapeviineapp.com/terms"
    }
}
