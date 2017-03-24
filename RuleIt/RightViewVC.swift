//
//  RightViewVC.swift
//  RuleIt
//
//  Created by Qin, Charles on 3/30/16.
//  Copyright © 2016 RuleIt Inc. All rights reserved.
//

import Foundation

protocol DataDelegate{
    func userDidSelectWorkTime(_ workTime: Double)
    func userDidSelectRestTime(_ restTime: Double)
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
        
        if UserDefaults.standard.object(forKey: "workTime") != nil {
            
            let wHour: Int = UserDefaults.standard.integer(forKey: "workTime") / 3600
            let wMin: Int = (UserDefaults.standard.integer(forKey: "workTime") - wHour * 3600) / 60
            let wSec: Int = UserDefaults.standard.integer(forKey: "workTime") - wHour * 3600 - wMin * 60
            workTimePicker.selectRow(wHour, inComponent: 0, animated: true)
            workTimePicker.selectRow(wMin, inComponent: 1, animated: true)
            workTimePicker.selectRow(wSec, inComponent: 2, animated: true)

            let rHour: Int = UserDefaults.standard.integer(forKey: "restTime") / 3600
            let rMin: Int = (UserDefaults.standard.integer(forKey: "restTime") - rHour * 3600) / 60
            let rSec: Int = UserDefaults.standard.integer(forKey: "restTime") - rHour * 3600 - rMin * 60
            restTimePicker.selectRow(rHour, inComponent: 0, animated: true)
            restTimePicker.selectRow(rMin, inComponent: 1, animated: true)
            restTimePicker.selectRow(rSec, inComponent: 2, animated: true)
            
            worktimeInSeconds = UserDefaults.standard.integer(forKey: "workTime")
            resttimeInSeconds = UserDefaults.standard.integer(forKey: "restTime")
            
        } else {
         
            workTimePicker.selectRow(30, inComponent: 2, animated: true)
            restTimePicker.selectRow(10, inComponent: 2, animated: true)
            worktimeInSeconds = 30
            resttimeInSeconds = 10
        }

        let timerManagerObj = timerManager(worktimerSetByUser: 0, resttimerSetByUser: 0)
        self.delegate = timerManagerObj
        
        upperView.layer.borderWidth = 1
        upperView.layer.borderColor = UIColor.gray.cgColor
        headsupMsg.alpha = 0
        
        if isClockInWorkingMode {
            workTimePicker.alpha = 0.4
            self.view.isUserInteractionEnabled = false
            
            restTimePicker.alpha = 0.4
            self.view.isUserInteractionEnabled = false
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // notification for invalidating/validating the picker view
        NotificationCenter.default.addObserver(self, selector: #selector(RightViewVC.validatePickerView(_:)), name: NSNotification.Name(rawValue: "validatePickerViewID"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RightViewVC.invalidatePickerView(_:)), name: NSNotification.Name(rawValue: "invalidatePickerViewID"), object: nil)
        
        if !isClockInWorkingMode {
            // update the mainView's clock display
            NotificationCenter.default.post(name: Notification.Name(rawValue: "userAdjustClockID"), object: nil)
            
            headsupMsg.alpha = 0
        } else {
            headsupMsg.alpha = 1
            headsupMsg.textColor = UIColor.yellow
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "rightVCDisappearID"), object: nil)

    }
   
    
    //MARK: NotificationCenter
    
    func validatePickerView(_ notification: Notification){
        
        workTimePicker.alpha = 1.0
        self.view.isUserInteractionEnabled = true
        
        restTimePicker.alpha = 1.0
        self.view.isUserInteractionEnabled = true
    }
    
    func invalidatePickerView(_ notification: Notification){
        
        workTimePicker.alpha = 0.4
        self.view.isUserInteractionEnabled = false
        
        restTimePicker.alpha = 0.4
        self.view.isUserInteractionEnabled = false
    }
    
    
    //MARK:
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }

    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if component == 0 {
            let hourData = hours[row]
            let myTitle = NSAttributedString(string: hourData, attributes: [NSForegroundColorAttributeName:UIColor.white])
            return myTitle
        }
        if component == 1 {
            let minData = minutes[row]
            let myTitle = NSAttributedString(string: minData, attributes: [NSForegroundColorAttributeName:UIColor.white])
            return myTitle
        }
        else {
            let secData = seconds[row]
            let myTitle = NSAttributedString(string: secData, attributes: [NSForegroundColorAttributeName:UIColor.white])
            return myTitle
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 70
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
       
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.white
        pickerLabel.font = UIFont(name: "Digital dream Fat Skew", size: 21)
        pickerLabel.textAlignment = NSTextAlignment.center
        
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
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
       
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
            UserDefaults.standard.set(worktimeInSeconds, forKey: "workTime")
            
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
            UserDefaults.standard.set(resttimeInSeconds, forKey: "restTime")

            if (delegate != nil){
                
                delegate!.userDidSelectRestTime(Double(resttimeInSeconds))
            }
        }
    }
    

}
