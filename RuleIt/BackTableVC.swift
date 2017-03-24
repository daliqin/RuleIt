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
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableArray[indexPath.row], for: indexPath) as UITableViewCell
        cell.textLabel?.text = tableArray[indexPath.row]
        cell.textLabel?.textColor = UIColor.white
        cell.selectionStyle = UITableViewCellSelectionStyle.gray
        cell.textLabel?.highlightedTextColor = UIColor.black
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableArray.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "HO:UR"
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title = self.tableView(tableView, titleForHeaderInSection: section)
        if (title == "HO:UR") {
            return 45.0
        }
        return 15.0
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Digital dream Fat", size: 14)!
    }
    
    func popAlertView(_ msgBody: String, identifier: String) {
        if isClockInWorkingMode {
            let alert = UIAlertController(title: "Heads Up", message: msgBody, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: { action in
                self.performSegue(withIdentifier: identifier, sender: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "validatePickerViewID"), object: nil)
                isClockInWorkingMode = false
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { action in
                self.revealViewController().revealToggle(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: identifier, sender: self)
        }
    }
}

