//
//  LoginViewController.swift
//  GrapeVines
//
//  Created by imac on 3/6/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnSignIn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        txtEmail.delegate = self
        txtPassword.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let user:FIRUser = (FIRAuth.auth()?.currentUser) {
            signedIn(user)
        } else {
            FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
                if (user != nil) {
                    self.signedIn(user!)
                }
            })
        }
    }
    
    func signedIn (_ user:FIRUser) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "tabbar")
    }
    
    @IBAction func onDaniel(_ sender: Any) {
        txtEmail.text = "daniel.pelto@yahoo.com"
        txtPassword.text = "pppppp"
    }
    
    @IBAction func onPaul(_ sender: Any) {
        txtEmail.text = "successmeter@outlook.com"
        txtPassword.text = "pppppp"
    }
    

    @IBAction func onSignIn(_ sender: Any) {
        let email:String = self.txtEmail.text!
        let password:String = self.txtPassword.text!
        
        if email == "" {
            Common.alert(title: "Login", message: "Please enter your email", viewController: self)
            return
        }
        
        if password == "" {
            Common.alert(title: "Login", message: "Please enter your password", viewController: self)
            return
        }
        
        SVProgressHUD.show()
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            SVProgressHUD.dismiss()
            if let error = error {
                Common.alert(title: "Login", message: error.localizedDescription , viewController: self)
            } else {
                UserDefaults.standard.set(email, forKey: "email")
                UserDefaults.standard.set("email", forKey:"signinMethod");
                
                self.signedIn(user!)
            }
        })
    }

    @IBAction func onGotoSignUp(_ sender: Any) {
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true);
    }
}



