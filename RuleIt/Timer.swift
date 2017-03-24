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
    fileprivate init() {} //This prevents others from using the default '()' initializer for this class.
    
    var countdownTimer: Foundation.Timer? = Foundation.Timer()
    var displayClockTimer : Foundation.Timer? = Foundation.Timer()
    var refreshClock : Foundation.Timer? = Foundation.Timer()
}
