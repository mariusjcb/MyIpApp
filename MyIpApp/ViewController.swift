//
//  ViewController.swift
//  MyIpApp
//
//  Created by Marius Ilie on 16/01/17.
//  Copyright © 2017 University of Bucharest - Marius Ilie. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    // MARK: Data
    
    var currentIP: String? {
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
    
    // MARK: UI
    
    private func updateUI() {
        if currentIP != nil {
            ipLabel.text = currentIP!
        } else {
            ipLabel.text = "Indisponibil"
        }
        
        spinner.stopAnimating()
        ipLabel.isHidden = false
    }
    
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var sessionSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getIP()
    }
    
    @IBAction func onRefreshTap(_ sender: Any) {
        ipLabel.isHidden = true
        spinner.startAnimating()
        
        if sessionSwitch.isOn {
            getIP()
        } else {
            getIPWithoutSession()
        }
    }
    
    // MARK: RestAPI
    
    private struct ipRestAPI {
        static let url = URL.init(string: "https://httpbin.org/ip")
        static let ipField = "origin"
    }
    
    func getIP() {
        json = nil
        let session = URLSession.init(configuration: .default)
        
        if let url = ipRestAPI.url {
            let task = session.dataTask(with: url) { [weak weakSelf = self] (data, response, error) in
                weakSelf?.json = data
            }
            
            task.resume()
        }
    }
    
    func getIPWithoutSession() {
        json = nil
        currentIP = nil
        
        if let url = ipRestAPI.url {
            json = try? Data.init(contentsOf: url)
        }
    }
}

