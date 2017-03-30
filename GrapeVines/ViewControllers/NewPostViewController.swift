//
//  NewPostViewController.swift
//  GrapeVines
//
//  Created by imac on 3/13/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import AVFoundation
import Firebase
import Foundation
import GeoFire
import Photos
import SDWebImage
import SVProgressHUD


class NewPostViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var btnPost: UIButton!
    @IBOutlet weak var mapViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var txtPost: PlaceholderTextView!
    @IBOutlet weak var raidusSlider: UISlider!
    @IBOutlet weak var radiusPanelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imgPost: FLAnimatedImageView!
    @IBOutlet weak var imgHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var radiusPanel: UIView!
    var type: C.PostType = .post
    
    
    private var locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    private var circle: GMSCircle?
    private var imagePath: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.isMyLocationEnabled = true
        
        //init location manager
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        circle = GMSCircle()
        
        self.txtPost.delegate = self
        self.txtTitle.delegate = self
        
        imgHeightConstraint.constant = 0
        updateUI()
        
        self.currentLocation = Common.currentLocation
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow  , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide  , object: nil)
    }
    
    func updateUI () {
        self.btnPost.isEnabled = false
        
        self.btnPost.setBackgroundColor(color: .gray, forUIControlState: .disabled)
        
        switch type {
        case .post:
            self.raidusSlider.value = 2.0
            self.btnPost.setTitle("Post", for: .normal)
            self.txtPost.placeholder = "Say what you like!It's anonymous and it's gone in 24 hours..."
            break
        case .photoBomb:
            self.raidusSlider.value = 0.5
            radiusPanelHeightConstraint.constant = 0
            self.radiusPanel.isHidden = true
            self.btnPost.setTitle("Photobomb", for: .normal)
            self.txtPost.placeholder = "Say what you like!It's anonymous and it's gone in 24 hours..."
            break
        case .grapeVine:
            self.raidusSlider.value = 0.5
            self.txtPost.text = ""
            //other attributes are default in storyboard
            break
        }
        
        self.txtTitle.becomeFirstResponder()
    }
    
    @IBAction func onClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onRadiusChange(_ sender: Any) {
        let radiusInMile:Double = Double(self.raidusSlider.value)
        if let currentLocation = self.currentLocation {
            MapUtil.setRadius(radiusInMile: radiusInMile, withPosition: currentLocation.coordinate, InMapView: self.mapView, circle: circle!)
        }
    }
    
    @IBAction func onAttach(_ sender: Any) {
        if self.type == .photoBomb {
            self.requestPresentImagePicker(type: .camera)
        } else {
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
    
    @IBAction func onPost(_ sender: Any) {
        let title = self.txtTitle.text
        let text = self.txtPost.text
        let radius = self.raidusSlider.value
        
        
        if let currentLocation = self.currentLocation {
            SVProgressHUD.show()
            let post = Post(userID: Common.curUserID()!, type: self.type, title: title, text: text, time: 0, longitude: currentLocation.coordinate.longitude, latitude: currentLocation.coordinate.latitude, radius: Double(radius), imageURL: self.imagePath)
            post.post(completionHandler: { (error) in
                SVProgressHUD.dismiss()
                self.dismiss(animated: true, completion: nil)
            })
        } else {
            Common.alert(title: "Post", message: "Unable to get your location.", viewController: self)
        }
        
    }
    
    private func presentImagePicker(type: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = type
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        var imageType : String?
        var ext : String?
        let metaData = FIRStorageMetadata.init()
        
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
                                    SVProgressHUD.dismiss()
                                    self?.imagePath = Common.sref.child(metadata!.path!).description
                                    self?.refreshPostBtn()
                                    self?.imgHeightConstraint.constant = 230
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
                        self.imagePath = Common.sref.child(metadata!.path!).description
                        self.imgPost.image = image
                        self.refreshPostBtn()
                        self.imgHeightConstraint.constant = 230
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
    
    //Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        currentLocation = location
        
        //TEST:

//        if let currentLocation = Common.currentLocation {
//            self.currentLocation = currentLocation
//        } else {
//            currentLocation = location
//        }
        //
        
        
        let radiusInMile:Double = Double(self.raidusSlider.value)
        MapUtil.setRadius(radiusInMile: radiusInMile, withPosition: (currentLocation?.coordinate)!, InMapView: self.mapView, circle: circle!)
        
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
    
    //MARK: TextField delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        refreshPostBtn()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 25 // Bool
    }
    
    //MARK: TextView Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        refreshPostBtn()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func refreshPostBtn(){
        let hasTitle = (txtTitle.text != "")
        let hasComment = (txtPost.text != "")
        let hasImage = (self.imagePath != nil)
        
        switch(self.type) {
        case .post:
            self.btnPost.isEnabled = hasTitle || hasComment
            break
        case .photoBomb:
            self.btnPost.isEnabled = hasImage && hasTitle
            break
        case .grapeVine:
            self.btnPost.isEnabled = hasTitle && hasComment
            break
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    
    //MARK: keyboard
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
//        if self.txtPost.isFirstResponder {
//            UIView.animate(withDuration: 0.3, animations: {
//                self.mapViewHeightConstraint.constant = 0
//            })
//        }
    }
    
    func keyboardWillHide() {
//        UIView.animate(withDuration: 0.3, animations: {
//            self.mapViewHeightConstraint.constant = 258
//        })
    }
}
