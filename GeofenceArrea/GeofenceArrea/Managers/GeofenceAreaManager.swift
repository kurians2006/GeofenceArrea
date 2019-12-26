//
//  GeofenceAreaManager.swift
//  GeofenceArrea
//
//  Created by Naeem Paracha on 26/12/2019.
//  Copyright © 2019 Naeem Paracha. All rights reserved.
//

import Foundation
import CoreLocation

//MARK: Delegate for enter and exit from the desired area.
public protocol GeofenceAreaManagerDelegate: AnyObject {
    
    func geofenceAreaControllerDidExitRegion(_ controller: GeofenceAreaManager)
    func geofenceAreaControllerDidEnterRegion(_ controller: GeofenceAreaManager)
    func geofenceAreaController(_ controller: GeofenceAreaManager, didFailedWithReason: String)
}

//MARK: State for device, its inside or outside.
enum DeviceLocationStatus {
    case deviceLocationStatusUnknown
    case deviceLocationStatusInside
    case deviceLocationStatusOutside
}

public class GeofenceAreaManager: NSObject, CLLocationManagerDelegate {
    
    //MARK: Vars and Lets
    var locationManager = CLLocationManager()
    var fakeLocationManager = CLLocationManager() // For testing purposes
    var currentWiFiName = String()
    var currentRegion : CLCircularRegion?
    var deviceLocationStatus : DeviceLocationStatus?
    let reachabilityController = NetworkReachabilityManager()
    weak var delegate: GeofenceAreaManagerDelegate?

    
    override init() {
        super.init()
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.distanceFilter = 2
        reachabilityController.delegate = self

        deviceLocationStatus = .deviceLocationStatusUnknown
    }
    
    func startMonitoring(geofenceArea: GeofenceAreaModel) {
       if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            delegate?.geofenceAreaController(self, didFailedWithReason: "Geofencing is not supported on this device!")
            return
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            delegate?.geofenceAreaController(self, didFailedWithReason:"You should grant permission to access the device location")
        }
        reachabilityController.startObserving()
        
        let fenceRegion = region(with: geofenceArea)
        currentWiFiName = geofenceArea.wifiName
        locationManager.startUpdatingLocation()
        locationManager.startMonitoring(for: fenceRegion)
    }
    
    func stopMonitoring(geofenceArea: GeofenceAreaModel) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geofenceArea.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func getDeviceCoordianates() -> CLLocationCoordinate2D? {
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
                return locationManager.location?.coordinate
        }
        return nil
    }
    
    // MARK: Monitoring changes from CLLocationManagerDelegate and NetworkReachabilityDelegate
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion){
        print("region: \(region) registered")
        // Lets manually force initial check, since delegate callbacks trigg only at enter or exit
        if let myMonitoredRegion = region as? CLCircularRegion {
            currentRegion = myMonitoredRegion
            initialCheckFor(region: myMonitoredRegion)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if deviceLocationStatus != .deviceLocationStatusInside && region is CLCircularRegion{
            deviceLocationStatus = .deviceLocationStatusInside
            delegate?.geofenceAreaControllerDidEnterRegion(self)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if deviceLocationStatus != .deviceLocationStatusOutside && region is CLCircularRegion{
            print("Device did exit region, will check wifi reachability")
            if NetworkReachabilityManager.getWiFiSsid() != currentWiFiName{
                print("Device is not connected to wifi named:\(currentWiFiName)")
                deviceLocationStatus = .deviceLocationStatusOutside
                delegate?.geofenceAreaControllerDidExitRegion(self)
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        deviceLocationStatus = .deviceLocationStatusUnknown
        delegate?.geofenceAreaController(self, didFailedWithReason: error.localizedDescription)
    }
    
    
    // MARK: private helpers
    private func region(with geofenceArea: GeofenceAreaModel) -> CLCircularRegion {
        let region = CLCircularRegion(center: geofenceArea.coordinate, radius: geofenceArea.radius, identifier: geofenceArea.identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    private func initialCheckFor(region: CLCircularRegion){
        if let currentCoordinates = getDeviceCoordianates() {
            if region.contains(currentCoordinates) && deviceLocationStatus != .deviceLocationStatusInside {
                deviceLocationStatus = .deviceLocationStatusInside
                delegate?.geofenceAreaControllerDidEnterRegion(self)
            }else if reachabilityController.reachabilityStatus != .reachableViaWiFi {
                deviceLocationStatus = .deviceLocationStatusOutside
                delegate?.geofenceAreaControllerDidExitRegion(self)
            }
        }
    }
}

//MARK: exteion for status change delegate
extension GeofenceAreaManager: NetworkReachabilityDelegate{
    public func networkReachabilityStatusChanged(status: ReachabilityStatus){
        switch status {
        case .reachableViaWiFi:
            if deviceLocationStatus != .deviceLocationStatusInside && NetworkReachabilityManager.getWiFiSsid() == currentWiFiName{
                print("Device is connected to WiFi, we can assume that device status is inside area")
                deviceLocationStatus = .deviceLocationStatusInside
                delegate?.geofenceAreaControllerDidEnterRegion(self)
            }
        case .unreachableViaWiFi:
            if deviceLocationStatus != .deviceLocationStatusOutside, let region = currentRegion, let currentCoordinates = getDeviceCoordianates() {
                print("Device is unreachable via WiFi we are trying to determine state by location")
                if region.contains(currentCoordinates) {
                    print("Device location is in geofence region, but without wifi connection")
                    delegate?.geofenceAreaControllerDidEnterRegion(self)
                }
            }
        case .unknown:
            print("Something weird is going on with determining wifi reachability")
        }
    }
}



