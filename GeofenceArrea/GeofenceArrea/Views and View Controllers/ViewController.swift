//
//  ViewController.swift
//  GeofenceArrea
//
//  Created by Naeem Paracha on 26/12/2019.
//  Copyright © 2019 Naeem Paracha. All rights reserved.
//

import UIKit
import CoreLocation

let wifiNameForSimulator = "simulatorWiFiNameForTesting" // For testing purposes

class ViewController: UIViewController, GeofenceAreaManagerDelegate {
   
    
    
    //MARK: Vars and Lets
    var radius: CLLocationDistance = CLLocationDistance(10.0) // hardcoded radius will change from textfield
    let identifier = NSUUID().uuidString // random identifier
    let geofenceAreaManager = GeofenceAreaManager()

    
    //MARK: IBOutlets
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var radiusTextField: UITextField!
    
    //MARK: IBOutlet Actions
    @IBAction func setLocationAction(_ sender: UIButton) {
        radiusTextField.resignFirstResponder()
        radius = (radiusTextField.text! as NSString).doubleValue
        if let coordinates = geofenceAreaManager.getDeviceCoordianates(){
            let geofenceArea = GeofenceAreaModel(coordinate:coordinates, radius: radius, wifiName: wifiNameForSimulator, identifier: identifier)
            geofenceAreaManager.startMonitoring(geofenceArea: geofenceArea)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        geofenceAreaManager.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    //MARK:Helper
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    //MARK: geofenceAreaManagerDelegate
    func geofenceAreaControllerDidExitRegion(_ controller: GeofenceAreaManager){
        self.view.backgroundColor = .red
        self.bottomLabel.text = "Device is outside."
    }
    
    func geofenceAreaControllerDidEnterRegion(_ controller: GeofenceAreaManager){
        self.view.backgroundColor = .green
        self.bottomLabel.text = "Device is inside."
    }
    
    func geofenceAreaController(_ controller: GeofenceAreaManager, didFailedWithReason: String){
        self.bottomLabel.text = didFailedWithReason
    }
}


