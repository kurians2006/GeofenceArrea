//
//  NetworkReachabilityManager.swift
//  GeofenceArrea
//
//  Created by Naeem Paracha on 26/12/2019.
//  Copyright © 2019 Naeem Paracha. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

//MARK: ENUM for states
public enum ReachabilityStatus {
    case unknown
    case reachableViaWiFi
    case unreachableViaWiFi
}

//MARK: Protocols to fire state changes
public protocol NetworkReachabilityDelegate: AnyObject {

    func networkReachabilityStatusChanged(status: ReachabilityStatus)
    
}

public class NetworkReachabilityManager: NSObject {
    
    //MARK: Vars and Lets
    var reachabilityStatus : ReachabilityStatus
    weak var delegate : NetworkReachabilityDelegate?
    let reachability = Reachability()!
    
    
    override init() {
        reachabilityStatus = .unknown
    }
    
    deinit {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }
    
    func startObserving(){
        NotificationCenter.default.addObserver(self, selector: #selector(checkForReachability(notification:)), name: .reachabilityChanged, object: reachability)
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start reachability notifier")
        }
    }
    
    //Reachability state change notification observer method
    @objc func checkForReachability(notification: Notification){
        guard let reachability = notification.object as? Reachability else{
            return
        }
        
        if reachability.connection == .wifi {
            print("Reachable via WiFi")
            reachabilityStatus = .reachableViaWiFi
            delegate?.networkReachabilityStatusChanged(status: .reachableViaWiFi)
        }else{
            reachabilityStatus = .unreachableViaWiFi
            delegate?.networkReachabilityStatusChanged(status: .unreachableViaWiFi)
            print("Not reachable or reachable via Cellular")
        }
    }
    
    class func getWiFiSsid() -> String? {
        #if targetEnvironment(simulator)
        // It's not possible to get wifi name on simulators
        return wifiNameForSimulator
        #endif
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        return ssid
    }
}
