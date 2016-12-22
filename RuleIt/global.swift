//
//  global.swift
//  RuleIt
//
//  Created by Qin, Charles on 4/5/16.
//  Copyright © 2016 RuleIt Inc. All rights reserved.
//

import Foundation

class timerManager : DataDelegate {
    
    var worktimerSetByUser = 0
    var resttimerSetByUser = 0
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var sharedTimer : timerManager?
    
    init(worktimerSetByUser : Int, resttimerSetByUser: Int){
        self.worktimerSetByUser = worktimerSetByUser
        self.resttimerSetByUser = resttimerSetByUser
    }
    
    func currentTimer() -> timerManager{
        
        sharedTimer = timerManager(worktimerSetByUser: appDelegate.workTimeValue, resttimerSetByUser: appDelegate.restTimeValue)
        return sharedTimer!
    }
 
//MARK:
//MARK: delegate functions
    
    func userDidSelectWorkTime(_ workTime: Double) {
      
        // called when user adjust the wheel
        appDelegate.workTimeValue = Int(workTime)
    }
    
    
    func userDidSelectRestTime(_ restTime: Double) {
        
        appDelegate.restTimeValue = Int(restTime)
    }
    
}
