//
//  InAppReview.swift
//  RuleIt
//
//  Created by Chin, Charles-CW on 11/18/17.
//  Copyright © 2017 RuleIt Inc. All rights reserved.
//

import Foundation
import StoreKit

public class InAppReivew {
    
    let runIncrementerSetting = "numberOfRuns"
    let mininumRunCount = 3
    let defaults = UserDefaults()

    func incrementAppRuns() {
        defaults.setValuesForKeys([runIncrementerSetting: getRunCounts() + 1])
    }
    
    func getRunCounts() -> Int {
        var runsFromUser = 0
        if let savedRuns = defaults.value(forKey: runIncrementerSetting) as? Int {
            runsFromUser = savedRuns
        }
        return runsFromUser
    }
    
    func showReview() {
        let actualRuns = getRunCounts()
        if actualRuns > mininumRunCount, #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
    }
    
    func showReivewInFeedback() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            UIApplication.shared.openURL(URL(string : "itms-apps://itunes.apple.com/app/id1130529290")!)
        }
    }
}
