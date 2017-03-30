//
//  MapUtils.swift
//  GrapeVines
//
//  Created by imac on 3/13/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Foundation
import MapKit

class MapUtil {
    
    class func translateCoordinate(coordinate: CLLocationCoordinate2D, metersLat: Double,metersLong: Double) -> (GMSCoordinateBounds) {
        var tempCoord1 = coordinate
        var tempCoord2 = coordinate
        
        let tempRegion = MKCoordinateRegionMakeWithDistance(coordinate, metersLat, metersLong)
        let tempSpan = tempRegion.span
        
        tempCoord1.latitude = coordinate.latitude + tempSpan.latitudeDelta
        tempCoord1.longitude = coordinate.longitude + tempSpan.longitudeDelta
        tempCoord2.latitude = coordinate.latitude - tempSpan.latitudeDelta
        tempCoord2.longitude = coordinate.longitude - tempSpan.longitudeDelta
        
        let tempBounds = GMSCoordinateBounds(coordinate: tempCoord1, coordinate: tempCoord2)
        return tempBounds
    }
    
    //radius in mile
    class func setRadius(radiusInMile: Double, withPosition position: CLLocationCoordinate2D,InMapView mapView: GMSMapView, circle: GMSCircle) {
        
        let radiusInMeter:Double = radiusInMile * 1609.344
        
        let bounds = MapUtil.translateCoordinate(coordinate: position, metersLat: radiusInMeter, metersLong: radiusInMeter)
        
        let update = GMSCameraUpdate.fit(bounds, withPadding: 5.0)    // padding set to 5.0
        
        mapView.moveCamera(update)
        
        // draw circle        
        circle.position = position
        circle.radius = radiusInMeter
        circle.map = mapView
        circle.fillColor = UIColor(red:0.09, green:0.6, blue:0.41, alpha:0.5)
        
        mapView.animate(toLocation: position) // animate to center
    }
}
