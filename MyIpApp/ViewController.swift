//
//  ViewController.swift
//  MyIpApp
//
//  Created by Marius Ilie on 16/01/17.
//  Copyright © 2017 University of Bucharest - Marius Ilie. All rights reserved.
//

import UIKit
import ReachabilitySwift
import UserNotifications

class ViewController: UIViewController {
    // MARK: Data
    
    weak var reachability = (UIApplication.shared.delegate as? AppDelegate)?.reachability
    weak var center = (UIApplication.shared.delegate as? AppDelegate)?.center
    
    var currentIP: String? {
        didSet {
            updateUI()
        }
    }
    
    var connection: String = Reachability.NetworkStatus.notReachable.description {
        didSet {
            updateUI()
        }
    }
    
    var json: Data? {
        didSet {
            if json != nil {
                if let parsedJson = (try? JSONSerialization.jsonObject(with: json!, options: .mutableContainers)) as? [String: Any] {
                    currentIP = parsedJson[ipRestAPI.ipField] as? String
                }
            } else {
                currentIP = nil
            }
        }
    }
    
    // MARK: Controller
    
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var ipTypeLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var sessionSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground(notification:)), name: .UIApplicationDidEnterBackground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.connectionChanged), name: ReachabilityChangedNotification, object: reachability)
        try? reachability?.startNotifier()
        
    }
    
    func appDidEnterBackground(notification: Notification) {
        var backgroundTask: UIBackgroundTaskIdentifier = 0
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
    }
    
    @IBAction func onRefreshTap(_ sender: Any) {
        getIP()
    }
    
    func connectionChanged(note: Notification) {
        if let reachability = note.object as? Reachability {
            connection = reachability.currentReachabilityString
            
            if connection != Reachability.NetworkStatus.notReachable.description {
                sendUserNotification(title: "Conexiune noua", description: "Tocmai ati trecut pe o conexiune " + connection + "\n\nVerifica noul IP")
            } else {
                sendUserNotification(title: "Fara conexiune", description: "Conexiunea a fost intrerupta")
            }
            
            getIP()
        }
    }
    
    func sendUserNotification(title: String, description body: String) {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default()
        content.title = title
        content.body = body
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest.init(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request)
    }
    
    // MARK: UI
    
    private func updateUI() {
        if connection != Reachability.NetworkStatus.notReachable.description {
            ipTypeLabel.text = connection + " IP:"
        } else {
            ipTypeLabel.text = connection
        }
        
        if currentIP != nil {
            ipLabel.text = currentIP!
        } else {
            ipLabel.text = "Indisponibil"
        }
        
        spinner.stopAnimating()
        ipLabel.isHidden = false
    }
    
    // MARK: RestAPI
    
    private struct ipRestAPI {
        static let url = URL.init(string: "https://httpbin.org/ip")
        static let ipField = "origin"
    }
    
    func getIP() {
        ipLabel.isHidden = true
        
        if connection != Reachability.NetworkStatus.notReachable.description
        {
            spinner.startAnimating()
            
            if let isOn = sessionSwitch?.isOn {
                if isOn {
                    getIPWithSession()
                } else {
                    getIPWithoutSession()
                }
            } else {
                getIPWithSession()
            }
        }
    }
    
    func getIPWithSession() {
        let session = URLSession.init(configuration: .default)
        
        if let url = ipRestAPI.url {
            let task = session.dataTask(with: url) { [weak weakSelf = self] (data, response, error) in
                weakSelf?.json = data
            }
            
            task.resume()
        } else {
            json = nil
        }
    }
    
    func getIPWithoutSession() {
        if let url = ipRestAPI.url {
            json = try? Data.init(contentsOf: url)
        } else {
            json = nil
        }
    }
}

