//
//  BackTableVC.swift
//  RuleIt
//
//  Created by Qin, Charles on 3/30/16.
//  Copyright © 2016 RuleIt Inc. All rights reserved.
//

import Foundation

class BackTableVC: UITableViewController {
    
    
    @IBOutlet var backTableView: UITableView!
    var tableArray = [String]()

    override func viewDidLoad() {
        
        tableArray = ["Home", "Action", "Settings"]
        self.revealViewController().rearViewRevealWidth = self.view.frame.width / 3.3
        
//        let frame = CGRectMake(0, 0, self.view.frame.size.width, 140)
//        let footerImageView = UIImageView(frame: frame)
//        let image: UIImage = UIImage(named: "transparentBG.png")!
//        footerImageView.image = image
//        footerImageView.contentMode = UIViewContentMode.ScaleAspectFit
//        footerImageView.alignmentRectInsets()
//        backTableView.tableFooterView = footerImageView
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(tableArray[indexPath.row], forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.text = tableArray[indexPath.row]
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        cell.textLabel?.highlightedTextColor = UIColor.blackColor()
        
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableArray.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
      
        switch indexPath.row {
        case 0:
            popAlertView("Are you sure you want to stop the timer to restart it?", identifier: "home")
            break;
        case 1:
            
            popAlertView("Are you sure you want to stop the timer to go to action page?", identifier: "action")
           
            break;
        case 2:
            popAlertView("Are you sure you want to stop the timer to go to settings page?", identifier: "settings")
            break;
            
        default:
            break;
        
        }
    }
    
// MARK: table view header
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "I.V.ELITE"
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
       
        let title = self.tableView(tableView, titleForHeaderInSection: section)
        if (title == "I.V.ELITE") {
            return 45.0
        }
        return 15.0
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Digital dream Fat", size: 11)!
        //header.textLabel?.textColor = UIColor.lightGrayColor()
    }
    
//    // MARK: table view footer
//    
//    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        return "To /nyour /nsuccess"
//    }
//    
//    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//
//        return 260.0
//    }
    
    // MARK: helper func
    
    func popAlertView(msgBody: String, identifier: String) {
        if isClockInWorkingMode {
            let alert = UIAlertController(title: "Heads Up", message: msgBody, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { action in
                self.performSegueWithIdentifier(identifier, sender: self)
                NSNotificationCenter.defaultCenter().postNotificationName("validatePickerViewID", object: nil)
                isClockInWorkingMode = false
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
                self.revealViewController().revealToggleAnimated(true)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            self.performSegueWithIdentifier(identifier, sender: self)
        }

    }
    
}











