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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let email = "dcharleschin@yahoo.com"
            let url = URL(string: "mailto:\(email)")
            UIApplication.shared.openURL(url!)
        }
        if indexPath.row == 1 {
            let activityViewController = UIActivityViewController(activityItems: ["This app is pretty legit. AppStore link: itunes.apple.com/app/id1130529290" as NSString], applicationActivities: nil)
            present(activityViewController, animated: true, completion: {})
            
        }
        if indexPath.row == 2 {
            InAppReivew().showReivewInFeedback()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
