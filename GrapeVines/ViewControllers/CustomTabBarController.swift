//
//  CustomTabBarController.swift
//  GrapeVines
//
//  Created by imac on 3/13/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation

class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {
    var alertMessage: UIAlertController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let cvc:UIViewController? = tabBarController.viewControllers?[tabBarController.selectedIndex]
        
        if tabBarController.viewControllers?[1] == viewController {
            //if post
            
            alertMessage = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
            if let alertMessage = alertMessage {
                let width = alertMessage.view.frame.size.width - 32
                
                let btnPost:UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: width, height: 75))
                btnPost.addTarget(self, action: #selector(onPost), for: .touchUpInside)
                let imgPost:UIImage = UIImage(named: "ic_post_pin")!
                btnPost.setImage(imgPost, for: .normal)
                let fontAttr = [NSFontAttributeName:UIFont.systemFont(ofSize:14.0)]
                let boldFontAttribute = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0)]
                let attrTextPost:NSMutableAttributedString = NSMutableAttributedString(string: "Post: Anyone can view and like this post. Only people inside the post radius can comment.\nLasts for 24 hours.", attributes: fontAttr)
                attrTextPost.addAttributes(boldFontAttribute, range: NSMakeRange(0, 5))
                btnPost.setAttributedTitle(attrTextPost, for: .normal)
                btnPost.setTitleColor(UIColor.darkGray , for: .normal)
                btnPost.titleLabel?.lineBreakMode = .byWordWrapping
                
                let btnPhotoBomb:UIButton = UIButton(frame: CGRect(x: 0, y: 75, width: width, height: 75))
                btnPhotoBomb.addTarget(self, action: #selector(onPhotoBomb), for: .touchUpInside)
                let imgPhotoBomb:UIImage = UIImage(named: "ic_photo_bomb")!
                btnPhotoBomb.setImage(imgPhotoBomb, for: .normal)
                let attrTextPhotoBomb:NSMutableAttributedString = NSMutableAttributedString(string: "Photo bomb: Post anonymous photo that only people within 1/2mile can see, like and comment on.\nLasts for 24 hours.", attributes: fontAttr)
                attrTextPhotoBomb.addAttributes(boldFontAttribute, range: NSMakeRange(0, 11))
                btnPhotoBomb.setAttributedTitle(attrTextPhotoBomb, for: .normal)
                btnPhotoBomb.setTitleColor(UIColor.darkGray , for: .normal)
                btnPhotoBomb.titleLabel?.lineBreakMode = .byWordWrapping
                
                let btnGrape:UIButton = UIButton(frame: CGRect(x: 0, y: 150, width: width, height: 100))
                btnGrape.addTarget(self, action: #selector(onGrapeVine), for: .touchUpInside)
                let imgGrape:UIImage = UIImage(named: "ic_grape")!
                btnGrape.setImage(imgGrape, for: .normal)
                let attrTextGrape:NSMutableAttributedString = NSMutableAttributedString(string: "Grape Vine: Only people who come inside your post radius can join this thread,but they can continue the conversation even after they've left the proximity.\nGrape Vines last for 3 days.", attributes: fontAttr)
                attrTextGrape.addAttributes(boldFontAttribute, range: NSMakeRange(0, 11))
                btnGrape.setAttributedTitle(attrTextGrape, for: .normal)
                btnGrape.setTitleColor(UIColor.darkGray , for: .normal)
                btnGrape.titleLabel?.lineBreakMode = .byWordWrapping
                
                alertMessage.view.addSubview(btnPost)
                alertMessage.view.addSubview(btnPhotoBomb)
                alertMessage.view.addSubview(btnGrape)
                
                let cancelAction:UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertMessage.addAction(cancelAction)
                
                cvc?.present(alertMessage, animated: true, completion: nil)
            }
            
            return false;
        }
        return true
    }
    
    func onPost() {
        navigate(type: .post)
    }
    
    func onPhotoBomb() {
        navigate(type: .photoBomb)
    }
    
    func onGrapeVine() {
        navigate(type: .grapeVine)
    }
    
    func navigate(type: C.PostType) {
        let cvc:UIViewController? = self.viewControllers?[self.selectedIndex]
        let newPostVC : NewPostViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "newpost") as! NewPostViewController
        newPostVC.type = type
        
        if let alertMessage = alertMessage {
            alertMessage.dismiss(animated: false, completion: { 
                cvc?.present(newPostVC, animated: true, completion: nil)
            })
        }
    }
    
    func showModal(obj:UIViewController) {
        let cvc:UIViewController? = self.viewControllers?[self.selectedIndex]
        cvc?.present(obj, animated: true, completion: nil)
    }
}
