//
//  ProfileViewController.swift
//  GrapeVines
//
//  Created by imac on 3/8/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Firebase
import MessageUI
import SVProgressHUD
import UIKit

class ProfileViewController :UIViewController, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate{
    
    @IBOutlet weak var editPanel: UIView!
    @IBOutlet weak var swPanel: UISegmentedControl!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var table: UITableView!
    
    private var hChange : FIRDatabaseHandle?
    var grapeVines: NSMutableArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.txtEmail.delegate = self
        self.txtPassword.delegate = self
        self.table.delegate = self
        self.table.dataSource = self
        
        self.txtEmail.text = UserDefaults.standard.string(forKey: "email")
        
        let n = Common.grapeVines.count
        
        for i in 0..<n {
            let key = Common.grapeVines[i] as! String
            addGrape(key: key)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(processAddGrapeNotification(_:)), name: Notification.Name("grapeAdd"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(processDeleteGrapeNotification(_:)), name: Notification.Name("grapeDelete"), object: nil)
    }
    func processAddGrapeNotification(_ notification: Notification) {
        if let key = notification.userInfo?["key"] as? String {
            addGrape(key: key)
        }
    }
    func addGrape(key: String) {
        Common.ref.child(C.Path.posts).child(key).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let post = Post(snapshot: snapshot)
                self.grapeVines.insert(post, at: 0)
                self.table.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .automatic)
            } else {
                Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.grapeVines).child(key).removeValue()
            }
        })
    }
    
    func processDeleteGrapeNotification(_ notification: NSNotification) {
        if let key = notification.userInfo?["key"] as? String {
            let count = self.grapeVines.count
            for i in 0..<count {
                if key == (self.grapeVines[i] as! Post).key {
                    self.grapeVines.removeObject(at: i)
                    self.table.deleteRows(at: [IndexPath.init(row: i, section: 0)], with: .automatic)
                    break
                }
            }
         }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let ref = Common.ref.child(C.Path.users).child(Common.curUserID()!)
        hChange = ref.observe(.value, with: { (snapshot) in
            if(snapshot.exists()) {
//                let user = User.init(snapshot: snapshot)
                
            }
            
        }, withCancel: { (error) in
            
        })
        
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow  , object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide  , object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let hChange = self.hChange {
            let ref = Common.ref.child(C.Path.users).child(Common.curUserID()!)
            ref.removeObserver(withHandle: hChange)
        }
    }
    
    private var lastOption: Int = 0
    @IBAction func onSegmantChange(_ sender: Any) {
        let sel = self.swPanel.selectedSegmentIndex
        
        if sel == 0 {
            self.table.isHidden = false
            self.editPanel.isHidden = true
            lastOption = 0
        } else if sel == 1 {
            self.editPanel.isHidden = false
            self.table.isHidden = true
            lastOption = 1
        } else {
            //invite from contacts
            self.swPanel.selectedSegmentIndex = lastOption
            invite()
        }
    }
    
    private func invite() {
        if (MFMessageComposeViewController.canSendText()) {
            let alert = UIAlertController(title: nil, message: "Invite your friends to join Grapeviine! Even though it's anonymous, it's more fun with friends.", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "Access Contacts", style: .default, handler: { (action) in
                let controller = MFMessageComposeViewController()
                controller.body = "Invite to Grapeviine iOS App\nhttps://itunes.apple.com/us/app/grapeviine/id1207160730?mt=8"
                controller.title = "Invite to Grapeviine"
                controller.subject = "Please try use this fantastic app!"
                controller.recipients = []
                controller.messageComposeDelegate = self
                self.present(controller, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Not Now", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        self.navigationController?.isNavigationBarHidden = false
//    }
    
    @IBAction func onChangePhoto(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = false
            picker.sourceType = .camera
            self.present(picker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Photo", style: .default, handler: { (action) in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let data = UIImageJPEGRepresentation(image, 0.8)
            let imgRef = Common.sref.child("avatar").child(Common.curUserID()!)
            let metaData = FIRStorageMetadata.init()
            metaData.contentType = "image/jpeg"
            let _ = imgRef.put(data!, metadata: metaData) { (metadata, error) in
                guard let metadata = metadata else {
                    SVProgressHUD.dismiss()
                    Common.alert(title: "Profile Image", message: "Can not upload image. Please check and try again.", viewController: self)
                    return
                }
                let downloadURL = Common.sref.child(metadata.path!).description
                let ref = Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.photoURL)
                
                ref.setValue(downloadURL, withCompletionBlock: { (error, ref) in
                    SVProgressHUD.dismiss()
                })
            }
        }
    
        picker.dismiss(animated: false, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: false, completion: nil)
    }
    
//    @IBAction func onNameChanged(_ sender: Any) {
//        SVProgressHUD.show()
//        let ref = Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.displayName)
//        
//        let displayName = self.txtDisplayName.text
//        ref.setValue(displayName, withCompletionBlock: { (error, ref) in
//            if let request = FIRAuth.auth()?.currentUser?.profileChangeRequest() {
//                request.displayName = displayName
//                request.commitChanges(completion: { (error) in
//                    SVProgressHUD.dismiss()
//                })
//            }
//        })
//    }
    
    @IBAction func onChangeEmail(_ sender: Any) {
        let email = self.txtEmail.text
        
        if email == "" {
            Common.alert(title: "Email", message: "Please input email", viewController: self)
            return
        }
        
        SVProgressHUD.show()
        FIRAuth.auth()?.currentUser?.updateEmail(email!, completion: { (error) in
            SVProgressHUD.dismiss()
            if let error = error {
                Common.alert(title: "Update email", message: error.localizedDescription, viewController: self)
            } else {
                UserDefaults.standard.set(email, forKey: "email")
            }
            
        })
    }
    @IBAction func onChangePassword(_ sender: Any) {
        SVProgressHUD.show()
        let password = self.txtPassword.text
        FIRAuth.auth()?.currentUser?.updatePassword(password!, completion: { (error) in
            SVProgressHUD.dismiss()
            if let error = error {
                Common.alert(title: "Change Password", message: error.localizedDescription, viewController: self)
            } else {
                
            }
        })
    }
    
//    func textViewDidEndEditing(_ textView: UITextView) {
//        SVProgressHUD.show()
//        let ref = Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.bio)
//        
//        let bio = self.txtBio.text
//        ref.setValue(bio, withCompletionBlock: { (error, ref) in
//            SVProgressHUD.dismiss()
//        })
//    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

//    func keyboardWillShow(notification: NSNotification) {
//        if txtEmail.isFirstResponder || txtPassword.isFirstResponder {
//            if let userInfo = notification.userInfo {
//                let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
//                
//                var rect = self.view.frame
//                rect.origin.y = -(endFrame?.size.height)!
//                
//                UIView.animate(withDuration: 0.3, animations: { 
//                    self.view.frame = rect;
//                })
//            }
//        }
//    }
//    
//    func keyboardWillHide() {
//        var rect = self.view.frame;
//        rect.origin.y = 0
//        
//        UIView.animate(withDuration: 0.3, animations: {
//            self.view.frame = rect;
//        })
//    }

    //MARK: Table Delegate and Datasource
    
    //MARK: Table Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.grapeVines.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "grapecell"
        let cell:GrapeCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! GrapeCell
        
        cell.tag = indexPath.row
        cell.selectionStyle = .none
        cell.accessoryType = .none
        
        let row = indexPath.row as Int
        let grape = grapeVines[row] as! Post
        
        cell.imgGrape.image = UIImage(named: "ic_grape")
        cell.lblTitle.text = grape.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row as Int
        let post = grapeVines[row] as! Post
        
        if post.blockedMe {
            Common.alert(title: post.title ?? "", message: "Poster blocked from this conversation", viewController: self)
        } else {
            if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "comment") as? CommentViewController {
                viewController.post = post
                if let navigator = navigationController {
                    navigator.pushViewController(viewController, animated: true)
                }
            }
        }
    }
}
