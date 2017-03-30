//
//  SignUpViewController.swift
//  GrapeVines
//
//  Created by imac on 3/6/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase

class SignUpViewController : UIViewController {
    
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPass: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func onSignUp(_ sender: Any) {
        let name:String = self.txtName.text!
        let email = self.txtEmail.text!
        let password = self.txtPassword.text!
        let confirmPass = self.txtConfirmPass.text!
        
        if name == "" {
            Common.alert(title: "Signup", message: "Please enter your name", viewController: self)
            return
        }
        
        if email == "" {
            Common.alert(title: "Signup", message: "Please enter your email", viewController: self)
        }
        
        if password == "" {
            Common.alert(title: "Signup", message: "Please enter your password", viewController: self)
            return
        }
        
        if password != confirmPass {
            Common.alert(title: "Signup", message: "Passwords do not match. Please check and try again.", viewController: self)
            return
        }
        
        SVProgressHUD.show()
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            
            if let error = error {
                SVProgressHUD.dismiss()
                
                Common.alert(title: "Signup", message: error.localizedDescription, viewController: self)
                return
            } else {
                UserDefaults.standard.set(email, forKey: "email")
                UserDefaults.standard.set("email", forKey:"signinMethod");
                
                if let changeRequest:FIRUserProfileChangeRequest? = user?.profileChangeRequest() {
                
                    changeRequest?.displayName = name
                    changeRequest?.commitChanges(completion: { (error) in
                        SVProgressHUD.dismiss()
                        if let error = error {
                            Common.alert(title: "Signup", message: error.localizedDescription, viewController: self)
                        } else {
                            self.doPostSignup(user: user!)
                        }
                    })
                } else {
                    SVProgressHUD.dismiss()
                }
            }
        })
    }
    
    private func doPostSignup (user:FIRUser) {
        var userInfo:[String: String] = [:]
        userInfo[C.UserFields.displayName] = user.displayName
        
        //write user information
        let path:String = "\(C.Path.users)/\(Common.curUserID()!)"
        Common.ref.child(path).setValue(userInfo)
        
        //subscribe to all notifications
        Common.subscribeToAll()
        
        //navigate to home
//        self.performSegue(withIdentifier: C.Segues.SignupToHome, sender: nil)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "tabbar")
    }
    
    @IBAction func onBackToSignIn(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true);
    }
}

