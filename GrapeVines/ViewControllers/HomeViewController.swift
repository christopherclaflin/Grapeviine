//
//  HomeViewController.swift
//  GrapeVines
//
//  Created by imac on 3/6/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Firebase
import GeoFire
import GooglePlaces
import MapKit
import UIKit

class HomeViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, GMSMapViewDelegate, PostCellDelegate{
    
    @IBOutlet weak var table: UITableView!
    var _hGrapeAdd:FIRDatabaseHandle?, _hGrapeDelete: FIRDatabaseHandle?
    var _hMyPostAdd:FIRDatabaseHandle?, _hMyPostDelete: FIRDatabaseHandle?
    var _hNotifChange:FIRDatabaseHandle?
    var feeds: NSMutableArray = []
    var myPosts: NSMutableArray = []
    var needsRefresh:Bool = true
    
    private var locationManager = CLLocationManager()
    private var circle: GMSCircle = GMSCircle()
    
    var headerView:UIView!
    var mapView: GMSMapView!
    var radiusSlider: UISlider!
    private var placesClient: GMSPlacesClient!
    private var currentPlace: GMSPlace?
    var circleQuery: GFCircleQuery?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.table.delegate = self
        self.table.dataSource = self
        
        let screenRect = UIScreen.main.bounds
        headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: screenRect.size.width, height: 360))
        mapView = GMSMapView.init(frame: CGRect.init(x: 0, y: 0, width: screenRect.size.width, height: 320))
        mapView.delegate = self
        
        radiusSlider = UISlider.init(frame: CGRect.init(x: 0, y: 320, width: screenRect.size.width, height: 40))
        radiusSlider.minimumValue = 0.1
        radiusSlider.maximumValue = 10
        radiusSlider.value = 2
        radiusSlider.isContinuous = false
        radiusSlider.addTarget(self, action: #selector(onRadiusChange(_:)), for: .valueChanged)
        
        headerView.addSubview(mapView)
        headerView.addSubview(radiusSlider)
        
        self.table.tableHeaderView = headerView
        
        mapView.isMyLocationEnabled = true
        
        Common.ref.child(".info/serverTimeOffset").observeSingleEvent(of: .value, with: { (snapshot) in
            Common.timeOffset = Double(snapshot.value as! Double)
        }) { (error) in
            
        }
        
        //init location manager
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        //current place
        placesClient = GMSPlacesClient.shared()

        //joined grape vines
        _hGrapeAdd = Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.grapeVines).observe(.childAdded, with: { (snapshot) in
            Common.grapeVines.insert(snapshot.key, at: 0)
            let notificationName = Notification.Name("grapeAdd")
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo:["key": snapshot.key])
        })

        _hGrapeDelete = Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.grapeVines).observe(.childRemoved, with: { (snapshot) in
            let key = snapshot.key as String
            
            for i in 0..<Common.grapeVines.count {
                if key == Common.grapeVines[i] as! String {
                    Common.grapeVines.remove(i)
                    break
                }
            }
            let notificationName = Notification.Name("grapeDelete")
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo:["key": snapshot.key])
        })
        
        _hMyPostAdd = Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.posts).observe(.childAdded, with: { (snapshot) in
            self.myPosts.insert(snapshot.key, at: 0)
            self.doAddPost(key: snapshot.key)
        })
        
        _hMyPostDelete = Common.ref.child(C.Path.users).child(Common.curUserID()!).child(C.UserFields.posts).observe(.childRemoved, with: { (snapshot) in
            let key = snapshot.key as String
            
            for i in 0..<self.myPosts.count {
                if key == self.myPosts[i] as! String {
                    self.myPosts.remove(i)
                    break
                }
            }
            
            self.doDeletePost(key: snapshot.key)
        })
        
        //notifications
        _hNotifChange = Common.ref.child(C.Path.unread).child(Common.curUserID()!).child(C.Path.notifications).observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                let unreadNotifs = snapshot.value as? Int ?? 0
                
                if unreadNotifs == 0 {
                    self.navigationController?.tabBarController?.tabBar.items?[2].badgeValue = nil
                }
                else {
                    self.navigationController?.tabBarController?.tabBar.items?[2].badgeValue = String(unreadNotifs)
                }
            }
        })
        
        Common.ref.child(C.Path.posts).observe(.childChanged, with: { (snapshot) in
            if snapshot.exists() {
                let key = snapshot.key
                
                let n = self.feeds.count
                for i in 0..<n {
                    if key == (self.feeds[i] as! Post).key {
                        let post = Post(snapshot: snapshot)
                        self.feeds.replaceObject(at: i, with: post)
                        self.table.reloadRows(at: [IndexPath.init(row: i, section: 0)], with: .automatic)
                    }
                }
            }
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        needsRefresh = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
    }
    
    //MARK: Table Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.feeds.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "post"
        let cell:PostCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! PostCell
        
        cell.tag = indexPath.row
        cell.delegate = self
        cell.selectionStyle = .none
        cell.accessoryType = .none
        
        let row = indexPath.row as Int
        
        cell.setCellData(post: feeds[row] as! Post)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row as Int
        let post = feeds[row] as! Post
        
        Common.pushCommentViewController(post: post, vc: self)
    }
    
    //Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        Common.currentLocation = location
        refreshMap()
        
        placesClient.currentPlace { (liklihoodList, error) in
            self.currentPlace = liklihoodList?.likelihoods[0].place
            Common.currentAddress = self.currentPlace?.formattedAddress ?? ""
        }

        if needsRefresh {
            needsRefresh = false
            reloadPosts()
        }
        
        commitLocation()
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
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
    
    func reloadPosts() {
        
        let center = Common.currentLocation
        let queryRadiusInKM = self.radiusSlider.value * Float(C.kilometerPerMile)
        
        if let _ = circleQuery {
            self.circleQuery?.removeAllObservers();
        }
        
        for i in 0..<self.feeds.count {
            let post = self.feeds[i] as! Post
            
            post.marker?.map = nil
        }
        
        feeds.removeAllObjects()
        self.table.reloadData()
        
        for i in 0..<self.myPosts.count {
            let key = self.myPosts[i] as! String
            
            self.doAddPost(key: key)
        }
        
        self.circleQuery = Common.geoFireForPost.query(at: center, withRadius: Double(queryRadiusInKM))
        
        
        self.circleQuery?.observeReady({
            self.circleQuery?.observe(.keyEntered, with: { (key, location) in
                self.doAddPost(key: key!)
            })
            
            self.circleQuery?.observe(.keyExited, with: { (key, location) in
                self.doDeletePost(key: key!)
            })
            
        })
    }
    
    private func doAddPost(key: String!) {
        
        //check if already added
        for i in 0..<self.feeds.count {
            let post = self.feeds[i] as! Post
            if key! == post.key {
                return
            }
        }
        
        //fetch Post
        Common.ref.child(C.Path.posts).child(key!).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let post = Post(snapshot: snapshot)
                
                if post.type != .post {
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: post.latitude, longitude: post.longitude)
                    marker.title = post.title
                    marker.snippet = nil
                    marker.map = self.mapView
                    
                    switch post.type {
                    case C.PostType.post:
                        marker.icon = UIImage(named: "ic_post_pin")
                        break
                    case C.PostType.photoBomb:
                        marker.icon = UIImage(named: "ic_photo_bomb")
                        break
                    case C.PostType.grapeVine:
                        marker.icon = UIImage(named: "ic_grape")
                        break
                    }
                    post.marker = marker
                }
                
                self.feeds.insert(post, at: 0)
                
                //sort feeds here
                self.feeds.sort(comparator: { (obj1, obj2) -> ComparisonResult in
                    let post1 = obj1 as! Post
                    let post2 = obj2 as! Post
                    
                    if post1.time <= post2.time {
                        return .orderedDescending
                    } else {
                        return .orderedAscending
                    }
                })
                
                var index = 0
                for i in 0..<self.feeds.count {
                    let aPost = self.feeds[i] as! Post
                    if aPost.key == post.key {
                        index = i
                        break
                    }
                }
                
                //
                self.table.insertRows(at: [IndexPath.init(row: index, section: 0)], with: .automatic)
            }
        })
    }
    
    private func doDeletePost(key: String!) {
        for i in 0..<self.feeds.count {
            let post = self.feeds[i] as! Post
            if key! == post.key {
                post.marker?.map = nil
                self.feeds.removeObject(at: i)
                self.table.deleteRows(at: [IndexPath.init(row: i, section: 0)], with: .automatic)
                break
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name("postDelete"), object: nil, userInfo:["key": key!])
    }
    
    @IBAction func onRadiusChange(_ sender: Any) {
        self.refreshMap()
        self.reloadPosts()
    }
    
    private func refreshMap() {
        let radiusInMile:Double = Double(self.radiusSlider.value)
        
        if let currentLocation = Common.currentLocation {
            MapUtil.setRadius(radiusInMile: radiusInMile, withPosition: currentLocation.coordinate, InMapView: self.mapView, circle: circle)
        }
    }
    
    
    
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        Common.currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
//        refreshMap()
//        placesClient.currentPlace { (liklihoodList, error) in
//            self.currentPlace = liklihoodList?.likelihoods[0].place
//            Common.currentAddress = self.currentPlace?.formattedAddress ?? ""
//        }
//        
//        //if needsRefresh {
//            needsRefresh = false
//            reloadPosts()
//        //}
//        
//        commitLocation()
    }
    
    //MARK: PostCellDelegate
    func onLike(post: Post) {

    }
    
    func onReply(post: Post) {
        Common.pushCommentViewController(post: post, vc: self)
    }
    
    //MARK: commit current location
    private func commitLocation() {
        if let location = Common.currentLocation {
            let key = Common.curUserID()!
            Common.geoFireForUser.setLocation(location, forKey: key)
        }
    }
}
