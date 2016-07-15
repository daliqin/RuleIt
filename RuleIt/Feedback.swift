//
//  Action.swift
//  RuleIt
//
//  Created by Qin, Charles on 3/30/16.
//  Copyright © 2016 RuleIt Inc. All rights reserved.
//

import Foundation
import Foundation
import UIKit

class Action: UITableViewController {
    
    @IBOutlet weak var hamburger: UIBarButtonItem!
    
    override func viewDidLoad() {
       
        hamburger.target = self.revealViewController()
        hamburger.action = #selector(SWRevealViewController.revealToggle(_:))
        
        //self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            let email = "time.Infinity@yahoo.com"
            let url = NSURL(string: "mailto:\(email)")
            UIApplication.sharedApplication().openURL(url!)
        }
        if indexPath.row == 1 {
            let activityViewController = UIActivityViewController(activityItems: ["Check out this Time Infinity app at: itunes.apple.com/app/id1130529290" as NSString], applicationActivities: nil)
            presentViewController(activityViewController, animated: true, completion: {})
            
        }
        if indexPath.row == 2 {
            UIApplication.sharedApplication().openURL(NSURL(string : "itms-apps://itunes.apple.com/app/id1130529290")!)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}