//
//  Timer.swift
//  RuleIt
//
//  Created by Dali Charles Chin on 6/1/16.
//  Copyright © 2016 RuleIt Inc. All rights reserved.
//

import Foundation

class Timer {
   
    static let sharedInstance = Timer()
    private init() {} //This prevents others from using the default '()' initializer for this class.
    
    
    var countdownTimer: NSTimer? = NSTimer()
    var displayClockTimer : NSTimer? = NSTimer()
    var refreshClock : NSTimer? = NSTimer()

    
}