//
//  PickerLabels.swift
//  RuleIt
//
//  Created by Dali Charles Qin on 5/1/18.
//  Copyright © 2018 RuleIt Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIPickerView {
    
    func setPickerLabels(labels: [Int:UILabel], containedView: UIView) { // [component number:label]
        
        let fontSize:CGFloat = 10
        let labelWidth:CGFloat = 75
        let x:CGFloat = self.frame.origin.x + 25
        let y:CGFloat = self.frame.size.height / 2
        
        for i in 0...self.numberOfComponents {
            
            if let label = labels[i] {
                
                if self.subviews.contains(label) {
                    label.removeFromSuperview()
                }
                
                label.frame = CGRect(x: x + labelWidth * CGFloat(i), y: y, width: labelWidth, height: fontSize)
                label.font = UIFont(name: "001 Interstellar Log", size: fontSize)
                label.backgroundColor = .clear
                label.textAlignment = NSTextAlignment.left
                
                self.addSubview(label)
            }
        }
    }
}
