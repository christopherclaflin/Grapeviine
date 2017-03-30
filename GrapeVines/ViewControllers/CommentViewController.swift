//
//  CommentViewController.swift
//  GrapeVines
//
//  Created by imac on 3/18/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import AVFoundation
import Firebase
import Foundation
import Photos
import SDWebImage
import SVProgressHUD

class CommentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate,  UIImagePickerControllerDelegate, UINavigationControllerDelegate, CommentCellDelegate {
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var sendPanel: UIView!
    @IBOutlet weak var txtComment: PlaceholderTextView!
    @IBOutlet weak var txtCommentHeightConstraint: NSLayoutConstraint! //default 36
    
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imgPostHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgPost: FLAnimatedImageView!
    private var postImagePath: String?
    
    var post: Post?
    var _hCommentAdd:FIRDatabaseHandle?, _hCommentDelete:FIRDatabaseHandle?, _hCommentChange:FIRDatabaseHandle?
    var comments: NSMutableArray = []
    var likes: Int = 0
    
    var btnPostLike: UIButton = UIButton(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.table.delegate = self
        self.table.dataSource = self
        
        self.txtComment.delegate = self
        self.txtComment.becomeFirstResponder()
        
        if let title = post?.title {
            self.navigationItem.title = title
        }
        
        self.imgPostHeightConstraint.constant = 0
        
        btnPostLike.setBackgroundImage(UIImage(named:"ic_like"), for: .normal)
        btnPostLike.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let item1 = UIBarButtonItem(customView: btnPostLike)
        self.navigationItem.rightBarButtonItem  = item1
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.deletePost(_:)), name: Notification.Name("postDelete"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deletePost(_:)), name: Notification.Name("grapeDelete"), object: nil)
        
        if let post = self.post {
            _hCommentAdd = Common.ref.child(C.Path.comments).child(post.key!).observe(.childAdded, with: { (snapshot) in
                if snapshot.exists() {
                    let comment = Comment(snapshot: snapshot, post: post)
                    self.comments.add(comment)
                    self.table.insertRows(at: [IndexPath.init(row: self.comments.count-1, section: 0)] , with: .automatic)
                    self.likes += comment.likesCount
                    
                    self.btnPostLike.setTitle(String(self.likes), for: .normal)
                }
            })
            
            _hCommentDelete = Common.ref.child(C.Path.comments).child(post.key!).observe(.childRemoved, with: { (snapshot) in
                if snapshot.exists() {
                    let n = self.comments.count
                    for i in 0..<n {
                        if(snapshot.key == (self.comments[i] as! Comment).key) {
                            self.likes -= (self.comments[i] as! Comment).likesCount
                            self.comments .removeObject(at: i)
                            self.table.deleteRows(at: [IndexPath.init(row: i, section: 0)], with: .automatic)
                            
                            self.btnPostLike.setTitle(String(self.likes), for: .normal)
                            break
                        }
                    }
                    
                }
            })
            
            _hCommentChange = Common.ref.child(C.Path.comments).child(post.key!).observe(.childChanged, with: { (snapshot) in
                if snapshot.exists() {
                    let n = self.comments.count
                    let updatedComment = Comment(snapshot: snapshot, post: post)
                    for i in 0..<n {
                        if(snapshot.key == (self.comments[i] as! Comment).key) {
                            self.likes -= (self.comments[i] as! Comment).likesCount
                            self.likes += updatedComment.likesCount
                            
                            self.comments.replaceObject(at: i, with: updatedComment)
                            self.table.reloadRows(at: [IndexPath.init(row: i, section: 0)], with: .automatic)
                            
                            self.btnPostLike.setTitle(String(self.likes), for: .normal)
                        }
                    }
                    
                }
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow  , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide  , object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    func deletePost(_ notification: NSNotification) {
        
        if let key = notification.userInfo?["key"] as? String {
            if key == post?.key {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func onSend(_ sender: Any) {
        let text = self.txtComment.text
        
        SVProgressHUD.show()
        
        let comment = Comment(postID: self.post!.key!, userID: Common.curUserID()!, title: nil, text: text, time: 0, imageURL: self.postImagePath)
        comment.post = self.post
        
        comment.comment(completionHandler: { (error) in
            SVProgressHUD.dismiss()
            self.postImagePath = nil;
            self.txtComment.text = ""
            self.txtCommentHeightConstraint.constant = 30
            self.imgPostHeightConstraint.constant = 0
            self.imgPost.image = nil
            self.imgPost.animatedImage = nil
            self.txtComment.resignFirstResponder()
        })

    }
    @IBAction func onAttach(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            self.requestPresentImagePicker(type: .camera)
        }))
        alert.addAction(UIAlertAction(title: "Photo", style: .default, handler: { (action) in
            self.requestPresentImagePicker(type: .photoLibrary)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func requestPresentImagePicker(type: UIImagePickerControllerSourceType) {
        
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        
        switch cameraAuthorizationStatus {
            
        case .authorized: break
        case .restricted: fallthrough
        case .denied: fallthrough
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType) { granted in
                if granted {
                    print("Granted access to \(cameraMediaType)")
                    self.presentImagePicker(type: type)
                } else {
                    print("Denied access to \(cameraMediaType)")
                    return
                }
            }
            return
        }
        self.presentImagePicker(type: type)
    }
    
    private func presentImagePicker(type: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = type
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var imageType : String?
        var ext : String?
        let metaData = FIRStorageMetadata.init()
        
        picker.dismiss(animated: true, completion: nil)
        
        if #available(iOS 8.0, *), let referenceURL = info[UIImagePickerControllerReferenceURL] as? URL {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceURL], options: nil)
            let asset = assets.firstObject
            
            SVProgressHUD.show()
            
            asset?.requestContentEditingInput(with: nil, completionHandler: { [weak self] (contentEditingInput, info) in
                if let imageFile = contentEditingInput?.fullSizeImageURL {
                    do {
                        let data = try Data.init(contentsOf: imageFile)
                        if let type = data.first {
                            if type == 0x47 {
                                //gif format
                                let image = FLAnimatedImage(animatedGIFData: data)
                                self?.imgPost.animatedImage = image
                                
                                imageType = "image/gif"
                                ext = "gif"
                            }
                            else if type == 0xff{
                                //image/jpeg
                                imageType = "image/jpeg"
                                ext = "jpg"
                                self?.imgPost.image = UIImage(data: data)
                            } else { //if type == 0x89 {
                                imageType = "image/png"
                                ext = "png"
                                self?.imgPost.image = UIImage(data: data)
                            }
                            
                            
                            
                            let imgRef = Common.sref.child(Common.curUserID()!).child("\(Common.timestamp()).\(ext!)")
                            metaData.contentType = imageType!
                            
                            imgRef.put(data, metadata: metaData) { (metadata, error) in
                                if let error = error {
                                    let nsError = error as NSError
                                    print("Error uploading: \(nsError.localizedDescription)")
                                    
                                    SVProgressHUD.dismiss()
                                } else {
                                    self?.postImagePath = Common.sref.child(metadata!.path!).description
                                    SVProgressHUD.dismiss()
                                    self?.imgPostHeightConstraint.constant = 160
                                }
                            }
                        } else {
                            //if data.first is nil
                            SVProgressHUD.dismiss()
                            
                            Common.alert(title: "Post", message: "Unable to load image", viewController: self!)
                        }
                        
                    } catch {
                        // if data is nil
                        
                        SVProgressHUD.dismiss()
                        
                        Common.alert(title: "Post", message: "Unable to load image", viewController: self!)
                    }
                }
            })
        }
        else {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                let data = UIImageJPEGRepresentation(image, 0.8)
                let imgRef = Common.sref.child(Common.curUserID()!).child("\(Common.timestamp()).jpg")
                metaData.contentType = "image/jpeg"
                
                let _ = imgRef.put(data!, metadata: metaData) { (metadata, error) in
                    if let error = error {
                        let nsError = error as NSError
                        print("Error uploading: \(nsError.localizedDescription)")
                        
                        SVProgressHUD.dismiss()
                    } else {
                        SVProgressHUD.dismiss()
                        self.postImagePath = Common.sref.child(metadata!.path!).description
                        self.imgPost.image = image
                        self.imgPostHeightConstraint.constant = 160
                    }
                }
            } else {
                Common.alert(title: "Post", message: "Unable to load image", viewController: self)
            }
        }

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Table Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "commentcell"
        let cell:CommentCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! CommentCell
        cell.delegate = self
        cell.tag = indexPath.row
        cell.selectionStyle = .none
        cell.accessoryType = .none
        
        let row = indexPath.row as Int
        
        cell.postType = self.post?.type ?? .post
        if row == 0 {
            cell.cellType = .header
        } else {
            cell.cellType = .comment
        }
        cell.setCellData(comment: comments[row] as! Comment)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.txtComment.resignFirstResponder()
        
        let row = indexPath.row as Int
        let comment = comments[row] as! Comment
        
        if row == 0 {
            //first row is original post
            
            return
        }
        
        //show popup kicking out
        
        
        if let post = self.post {
            let text = comment.text ?? ""
            let posterID = post.userID
            let commenterID = comment.userID
            
            
            if posterID == Common.curUserID()! && commenterID != Common.curUserID()! {
                let alert = UIAlertController(title: nil, message: text, preferredStyle: UIAlertControllerStyle.actionSheet)
            
                alert.addAction(UIAlertAction(title: "KICK USER FROM GROUP?", style: .destructive, handler: { (action) in
                    post.blockUser(userID: commenterID)
                    
                    Common.ref.child(C.Path.comments).child(post.key!).child(comment.key!).removeValue()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    //MARK: keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    private var panelY: CGFloat = 0
    func keyboardWillShow(notification: NSNotification) {
        
        let tabBarHeight = self.navigationController?.tabBarController?.tabBar.frame.size.height ?? 0
        
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            
            UIView.animate(withDuration: 0.3, animations: {
                self.bottomConstraint.constant = (endFrame?.size.height)! - tabBarHeight
            })
        }
    }
    
    func keyboardWillHide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.bottomConstraint.constant = 0
        })
    }
    
    //MARK: TextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    //MARK: TextViewDelegate
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        txtCommentHeightConstraint.constant = max(newSize.height, 30)
        
        return true
    }
    
    
    
    //MARK: CommentCellDelegate
    func onLike(like: Bool) {
        
    }
}
