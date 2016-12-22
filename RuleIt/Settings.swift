//
//  Settings.swift
//  RuleIt
//
//  Created by Qin, Charles on 3/30/16.
//  Copyright © 2016 RuleIt Inc. All rights reserved.
//

import Foundation
import UIKit

class Settings: UITableViewController {
 
    @IBOutlet weak var hamburger: UIBarButtonItem!
    @IBOutlet weak var btnSoundSwhOutlet: UISwitch!
    @IBOutlet weak var screenOnSwhOutlet: UISwitch!
    
    let vc = ViewController()
    var btnSoundEffect = true
   
    override func viewDidLoad() {
        
        hamburger.target = self.revealViewController()
        hamburger.action = #selector(SWRevealViewController.revealToggle(_:))
        //self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        btnSoundSwhOutlet.isOn = UserDefaults.standard.bool(forKey: "btnSoundSwitchState")
        screenOnSwhOutlet.isOn = UserDefaults.standard.bool(forKey: "screenLitSwitchState")
    }
    
    
    @IBAction func btnSoundSwitch(_ sender: AnyObject) {
        
        (sender.isOn != nil) ? (btnSoundEffect = true) : (btnSoundEffect = false)
        vc.btnSoundEffect = btnSoundEffect
        UserDefaults.standard.set(btnSoundSwhOutlet.isOn, forKey: "btnSoundSwitchState")

    }
    
    
    @IBAction func screenOnSwitch(_ sender: AnyObject) {
       
        if sender.isOn != nil {
            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        UserDefaults.standard.set(screenOnSwhOutlet.isOn, forKey: "screenLitSwitchState")


    }
    
}
