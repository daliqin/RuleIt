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
        
        btnSoundSwhOutlet.on = NSUserDefaults.standardUserDefaults().boolForKey("btnSoundSwitchState")
        screenOnSwhOutlet.on = NSUserDefaults.standardUserDefaults().boolForKey("screenLitSwitchState")
    }
    
    
    @IBAction func btnSoundSwitch(sender: AnyObject) {
        
        (sender.on != nil) ? (btnSoundEffect = true) : (btnSoundEffect = false)
        vc.btnSoundEffect = btnSoundEffect
        NSUserDefaults.standardUserDefaults().setBool(btnSoundSwhOutlet.on, forKey: "btnSoundSwitchState")

    }
    
    
    @IBAction func screenOnSwitch(sender: AnyObject) {
       
        if sender.on != nil {
            UIApplication.sharedApplication().idleTimerDisabled = true
        } else {
            UIApplication.sharedApplication().idleTimerDisabled = false
        }
        NSUserDefaults.standardUserDefaults().setBool(screenOnSwhOutlet.on, forKey: "screenLitSwitchState")


    }
    
}