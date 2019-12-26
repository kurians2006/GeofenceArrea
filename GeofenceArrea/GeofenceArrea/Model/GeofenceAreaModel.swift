//
//  GeofenceAreaModel.swift
//  GeofenceArrea
//
//  Created by Naeem Paracha on 26/12/2019.
//  Copyright © 2019 Naeem Paracha. All rights reserved.
//

import Foundation
import CoreLocation

class GeofenceAreaModel: NSObject {
    
    //MARK: Vars and Lets
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    var identifier: String
    var wifiName: String
    
    
    //MARK:Initializer
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, wifiName: String, identifier:String) {
        self.coordinate = coordinate
        self.radius = radius
        self.wifiName = wifiName
        self.identifier = identifier
    }
}
