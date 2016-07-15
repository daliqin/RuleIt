//
//  RightViewVC.swift
//  RuleIt
//
//  Created by Qin, Charles on 3/30/16.
//  Copyright © 2016 RuleIt Inc. All rights reserved.
//

import Foundation

protocol DataDelegate{
    func userDidSelectWorkTime(workTime: Double)
    func userDidSelectRestTime(restTime: Double)
}

class RightViewVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
  
    @IBOutlet weak var workTimePicker: UIPickerView!
    @IBOutlet weak var restTimePicker: UIPickerView!
    @IBOutlet weak var upperView: UIView!
    @IBOutlet weak var headsupMsg: UILabel!
    
    var delegate:DataDelegate? = nil
    
    var hours = ["00","01","02","03"]
    var minutes = ["00","01","02","03","04", "05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24", "25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44", "45","46","47","48","49","50","51","52","53","54","55","56","57","58","59"]
    var seconds = ["00","01","02","03","04", "05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24", "25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44", "45","46","47","48","49","50","51","52","53","54","55","56","57","58","59"]
    
    var worktimeHour = 0
    var resttimeHour = 0
    var worktimeMin = 0
    var resttimeMin = 0
    var worktimeSec = 0
    var resttimeSec = 0
    
    // variables that hold the final time picked
    var worktimeInSeconds = 0
    var resttimeInSeconds = 0
    
    //MARK:
    //MARK: viewlife cycle

    override func viewDidLoad() {
     
        self.revealViewController().rightViewRevealWidth = self.view.frame.width - 60
        workTimePicker.delegate = self
        workTimePicker.dataSource = self
        
        restTimePicker.delegate = self
        restTimePicker.dataSource = self
        
        if NSUserDefaults.standardUserDefaults().objectForKey("workTime") != nil {
            
            let wHour: Int = NSUserDefaults.standardUserDefaults().integerForKey("workTime") / 3600
            let wMin: Int = (NSUserDefaults.standardUserDefaults().integerForKey("workTime") - wHour * 3600) / 60
            let wSec: Int = NSUserDefaults.standardUserDefaults().integerForKey("workTime") - wHour * 3600 - wMin * 60
            workTimePicker.selectRow(wHour, inComponent: 0, animated: true)
            workTimePicker.selectRow(wMin, inComponent: 1, animated: true)
            workTimePicker.selectRow(wSec, inComponent: 2, animated: true)

            let rHour: Int = NSUserDefaults.standardUserDefaults().integerForKey("restTime") / 3600
            let rMin: Int = (NSUserDefaults.standardUserDefaults().integerForKey("restTime") - rHour * 3600) / 60
            let rSec: Int = NSUserDefaults.standardUserDefaults().integerForKey("restTime") - rHour * 3600 - rMin * 60
            restTimePicker.selectRow(rHour, inComponent: 0, animated: true)
            restTimePicker.selectRow(rMin, inComponent: 1, animated: true)
            restTimePicker.selectRow(rSec, inComponent: 2, animated: true)
            
            worktimeInSeconds = NSUserDefaults.standardUserDefaults().integerForKey("workTime")
            resttimeInSeconds = NSUserDefaults.standardUserDefaults().integerForKey("restTime")
            
        } else {
         
            workTimePicker.selectRow(30, inComponent: 2, animated: true)
            restTimePicker.selectRow(10, inComponent: 2, animated: true)
            worktimeInSeconds = 30
            resttimeInSeconds = 10
        }

        let timerManagerObj = timerManager(worktimerSetByUser: 0, resttimerSetByUser: 0)
        self.delegate = timerManagerObj
        
        upperView.layer.borderWidth = 1
        upperView.layer.borderColor = UIColor.grayColor().CGColor
        headsupMsg.alpha = 0
        
        if isClockInWorkingMode {
            workTimePicker.alpha = 0.4
            self.view.userInteractionEnabled = false
            
            restTimePicker.alpha = 0.4
            self.view.userInteractionEnabled = false
        }

    }
    
    override func viewDidAppear(animated: Bool) {
        
        // notification for invalidating/validating the picker view
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RightViewVC.validatePickerView(_:)), name: "validatePickerViewID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RightViewVC.invalidatePickerView(_:)), name: "invalidatePickerViewID", object: nil)
        
        if !isClockInWorkingMode {
            // update the mainView's clock display
            NSNotificationCenter.defaultCenter().postNotificationName("userAdjustClockID", object: nil)
            
            headsupMsg.alpha = 0
        } else {
            headsupMsg.alpha = 1
            headsupMsg.textColor = UIColor.orangeColor()
        }
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        NSNotificationCenter.defaultCenter().postNotificationName("rightVCDisappearID", object: nil)

    }
   
    
    //MARK: NotificationCenter
    
    func validatePickerView(notification: NSNotification){
        
        workTimePicker.alpha = 1.0
        self.view.userInteractionEnabled = true
        
        restTimePicker.alpha = 1.0
        self.view.userInteractionEnabled = true
    }
    
    func invalidatePickerView(notification: NSNotification){
        
        workTimePicker.alpha = 0.4
        self.view.userInteractionEnabled = false
        
        restTimePicker.alpha = 0.4
        self.view.userInteractionEnabled = false
    }
    
    
    //MARK:
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if component == 0 {
            return hours.count
        }
        if component == 1 {
            return minutes.count
        }
        else {
            return seconds.count
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 3
    }

    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if component == 0 {
            let hourData = hours[row]
            let myTitle = NSAttributedString(string: hourData, attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
            return myTitle
        }
        if component == 1 {
            let minData = minutes[row]
            let myTitle = NSAttributedString(string: minData, attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
            return myTitle
        }
        else {
            let secData = seconds[row]
            let myTitle = NSAttributedString(string: secData, attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
            return myTitle
        }
        
    }
    
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 70
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
       
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.whiteColor()
        pickerLabel.font = UIFont(name: "Digital dream Fat Skew", size: 21)
        pickerLabel.textAlignment = NSTextAlignment.Center
        
        if component == 0 {
             pickerLabel.text = hours[row]
            return pickerLabel
        }
        if component == 1 {
             pickerLabel.text = minutes[row]
            return pickerLabel
        }
        else{
            pickerLabel.text = seconds[row]
            return pickerLabel
        }
        
    }
    
    //MARK:
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if component == 0 {
            return hours[row]
        }
        if component == 1 {
            return minutes [row]
        }
        else {
            return seconds[row]
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
       
        if pickerView.tag == 1{
            
            if component == 0 {
                worktimeHour = Int(hours[row])!
            }
            if component == 1 {
                worktimeMin = Int(minutes[row])!
            }
            if component == 2 {
                worktimeSec = Int(seconds[row])!
            }
            worktimeInSeconds = (worktimeHour * 3600) + (worktimeMin * 60) + worktimeSec
            NSUserDefaults.standardUserDefaults().setInteger(worktimeInSeconds, forKey: "workTime")
            
            if (delegate != nil){
                
                delegate!.userDidSelectWorkTime(Double(worktimeInSeconds))
            }

        } else {
            
            if component == 0 {
                resttimeHour = Int(hours[row])!
            }
            if component == 1 {
                resttimeMin = Int(minutes[row])!
            }
            if component == 2 {
                resttimeSec = Int(seconds[row])!
            }
            resttimeInSeconds = (resttimeHour * 3600) + (resttimeMin * 60) + resttimeSec
            NSUserDefaults.standardUserDefaults().setInteger(resttimeInSeconds, forKey: "restTime")

            if (delegate != nil){
                
                delegate!.userDidSelectRestTime(Double(resttimeInSeconds))
            }
        }
    }
    

}