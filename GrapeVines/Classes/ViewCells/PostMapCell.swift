//
//  PostMapCell.swift
//  GrapeVines
//
//  Created by imac on 3/13/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation

protocol PostMapCellDelegate {
    func onUpdateRadius(inMile: Float)
}

class PostMapCell: UITableViewCell {
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var radiusSlider: UISlider!
    private var circle: GMSCircle = GMSCircle()
    
    var delegate: PostMapCellDelegate?
    var currentLocation: CLLocation?
    
    func initialize (){
        mapView.isMyLocationEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(onLocationChanged(notification:)), name: Notification.Name("currentLocationChanged"), object: nil)
    }
    
    @IBAction func onRadiusChange(_ sender: Any) {
        delegate?.onUpdateRadius(inMile: radiusSlider.value)
        
        self.refreshMap()
    }
    
    private func refreshMap() {
        let radiusInMile:Double = Double(self.radiusSlider.value)
        
        if let currentLocation = self.currentLocation {
            MapUtil.setRadius(radiusInMile: radiusInMile, withPosition: currentLocation.coordinate, InMapView: self.mapView, circle: circle)
        }
    }
    
    @objc private func onLocationChanged(notification: Notification) {
        if let currentLocation = notification.object as? CLLocation {
            self.currentLocation = currentLocation
            self.refreshMap()
        }
        
    }
}
