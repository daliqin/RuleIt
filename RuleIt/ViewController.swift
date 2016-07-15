//
//  ViewController.swift
//  RuleIt
//
//  Created by Qin, Charles on 3/30/16.
//  Copyright © 2016 RuleIt Inc. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore
import AVFoundation
import AudioToolbox
import CoreTelephony
import Instructions
import ChameleonFramework

var isClockInWorkingMode = false // global declaration before class. Don't move it

class ViewController: UIViewController,SWRevealViewControllerDelegate, CoachMarksControllerDataSource, CoachMarksControllerDelegate {

    @IBOutlet weak var open: UIBarButtonItem!
    @IBOutlet weak var AdjustTime: UIBarButtonItem!
    @IBOutlet weak var timer: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var plusOneMin: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var skipBtn: UIButton!
    @IBOutlet weak var worktimeLabel: UILabel!
    @IBOutlet weak var resttimeLabel: UILabel!
    @IBOutlet weak var currentTimeDisplay: UIButton!
    @IBOutlet weak var currentDateDisplay: UIButton!
    @IBOutlet weak var volumeBar: UISlider!
    @IBOutlet weak var addMinOutlet: UILabel!
    @IBOutlet weak var autoSwitchBtn: UIButton!
    @IBOutlet weak var autoSwitchCtnDwnLbl: UILabel!
    
    var isStartPressed : Bool = false
    var presetWorkTimeByUser = 20.0
    var presetRestTimeByUser = 0.0
    var presetTime = 0.0
    var progress : Float = 0.0
    var secondCountdown = 0
    var iteration = 0
    var progressFull : Bool = false
    var firstRun : Bool = true
    var delegate : SWRevealViewControllerDelegate?
    let myAppDelegate : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let playStop = UIButton()
    var isWorktimeClockActive = true
    var skipRest = false
    var displayingAMPM = true
    var displayingDate = true
    var refreshCurrentDateAndTime = NSTimer()
    var audioPlayer = AVAudioPlayer()
    var addMinCount = 0
    var autoSwitch = false
    var oldStatusText = ""
    var isPausing = false
    var btnSoundEffect = true
    var screenAlwaysLit = false
    let currCall = CTCallCenter()
    var autoSwitchInterval = 3
    var autoSwitchTimer = NSTimer?()
    
    // instruction view
    let pointOfInterest = UIView()
    var coachMarksController: CoachMarksController?
    
    let workTimeText = "Welcome!😎 Super quick walk-through! \nTimer is going to jump between 2 modes:  \nWORKING 💪 and RESTING 😪. \n\nHere is your work mode duration, which can be changed later. When work time runs out, hit next ⍄ to jump to the resting period"
    let restTimeText = "This is the rest-mode duration. \n\nAfter resting is done, hit next ⍄ again to get back to work-mode"
    let addMinText = "In case you are running out of time when timer is ongoing, this adds more minutes on-the-go ☀️"
    let autoSwitchText = "Want to make the jumping back and forth between modes 🤖automatic? Enable this!😇"
    let skipRestText = "In case you want to skip the next rest, enable this will keep your timer in working mode alone, until you disable it 😏."
    let volumeControlText = "This bar controls both button tapping sound volume and the alert sound volume 📢. \nYou can turn off tapping sound in Settings ⚙. \n\n🎉That's it!! You are good to go!😃"

    //MARK:
    //MARK: LifeCycle & Notification
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // menuViews instantiation
        open.target = self.revealViewController()
        open.action = #selector(SWRevealViewController.revealToggle(_:))
        AdjustTime.target = self.revealViewController()
        AdjustTime.action = #selector(SWRevealViewController.rightRevealToggle(_:))
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        // set the instruction view
        self.coachMarksController = CoachMarksController()
        self.coachMarksController?.allowOverlayTap = true
        self.coachMarksController?.dataSource = self
        self.worktimeLabel?.layer.cornerRadius = 4.0
        self.resttimeLabel?.layer.cornerRadius = 4.0
        self.plusOneMin?.layer.cornerRadius = 4.0
        self.autoSwitchBtn?.layer.cornerRadius = 4.0
        self.skipBtn?.layer.cornerRadius = 4.0
        self.volumeBar?.layer.cornerRadius = 4.0
        let skipView = CoachMarkSkipDefaultView()
        skipView.setTitle("Skip", forState: .Normal)
        self.coachMarksController?.skipView = skipView
        self.coachMarksController?.overlayBackgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.91)
        
        // my timer presets
        displayClock()
        stopBtn.enabled = false
        stopBtn.alpha = 0.5
        progressBar.progress = 0.0
        playPauseBtn.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
        playPauseBtn.alpha = 1.0
        plusOneMin.enabled = false
        plusOneMin.alpha = 0.5
        nextBtn.enabled = true
        
        status.text = "work mode"
        status.textColor = UIColor.cyanColor()
        status.alpha = 1.0
        
        worktimeLabel.layer.backgroundColor = UIColor.darkTextColor().CGColor
        worktimeLabel.layer.cornerRadius = 8
        resttimeLabel.layer.backgroundColor = UIColor.darkTextColor().CGColor
        resttimeLabel.layer.cornerRadius = 8
        
        volumeBar.value = NSUserDefaults.standardUserDefaults().floatForKey("volumeBar") ?? 0.5

        let date = NSDate()
        let dateOutput = NSDateFormatter()
        dateOutput.locale = NSLocale(localeIdentifier:"en_US")
        dateOutput.dateFormat = "MMMM d"
        currentDateDisplay.setTitle(dateOutput.stringFromDate(date), forState: UIControlState.Normal)
        let timeOutput = NSDateFormatter()
        timeOutput.locale = NSLocale(localeIdentifier:"en_US")
        timeOutput.dateFormat = "h:mm a"
        currentTimeDisplay.setTitle(timeOutput.stringFromDate(date), forState: UIControlState.Normal)
        
        // refreshing the Date/Time display
        refreshCurrentDateAndTime = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ViewController.refreshCurrentDT), userInfo: nil, repeats: true)
        
        // notification center for receiving if user has slide to the right menu
        NSNotificationCenter.defaultCenter().addObserver(self,
                                         selector: #selector(ViewController.userAdjustClock(_:)),
                                         name: "userAdjustClockID",
                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                         selector: #selector(ViewController.rightVCDidDisappear(_:)),
                                         name: "rightVCDisappearID",
                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                         selector: #selector(ViewController.comebackFromSuspendidState(_:)),
                                         name: "comebackFromSuspendidStateID",
                                         object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
       
        // first time running, set state to has launched
        let hasLaunched =  NSUserDefaults.standardUserDefaults().boolForKey("HasLaunched")
        if !hasLaunched {
            self.coachMarksController?.startOn(self)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunched")
        }
        
        btnSoundEffect = NSUserDefaults.standardUserDefaults().boolForKey("btnSoundSwitchState")
        UIApplication.sharedApplication().idleTimerDisabled = NSUserDefaults.standardUserDefaults().boolForKey("screenLitSwitchState")

    }
    
    func comebackFromSuspendidState(notification: NSNotification) {
    
        let timeSpotWhenSuspended = myAppDelegate.userDefaults.valueForKey("TimeSpot")
        if timeSpotWhenSuspended != nil && isStartPressed == true {
            
            let currentTime = NSDate()
            let timeInterval: Double = currentTime.timeIntervalSinceDate(timeSpotWhenSuspended as! NSDate);
            if secondCountdown < Int(timeInterval){
              
                secondCountdown = 0
                progress = 1
                
            } else {
                secondCountdown -= Int(timeInterval)
                progress += Float (timeInterval / presetTime)
            }
            
        }
    }
    
    func userAdjustClock(notification: NSNotification){
       
        myAppDelegate.displayClockTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(ViewController.displayClock), userInfo: nil, repeats: true)

    }
    
    func rightVCDidDisappear(notification: NSNotification){
        if myAppDelegate.displayClockTimer != nil{
            myAppDelegate.displayClockTimer!.invalidate()
        }
    }
  
    //MARK:
    //MARK: Timer setup
    
    func setTimer() {
        
        myAppDelegate.countdownTimer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(ViewController.timerRun), userInfo: nil, repeats: true)
    }
    
    func timerRun(){
        
        iteration += 1
        progress += Float (0.01 / presetTime)
        self.progressBar.setProgress(progress, animated: true)
        let minutes : Int = secondCountdown / 60
        let seconds : Int = secondCountdown - (minutes * 60)
        if minutes + seconds != 0 {
            let timerOutlet : String = String(format: "%02d:%02d", minutes, seconds)
            timer.text = timerOutlet
        }
        myAppDelegate.autoSwitch = autoSwitch
       
        if iteration == 100 {
          
            myAppDelegate.timeleft = Double(secondCountdown)
            secondCountdown -= 1
            if secondCountdown == 0 || secondCountdown < 0 {
                
                myAppDelegate.countdownTimer!.invalidate()
                myAppDelegate.countdownTimer = nil
                playPauseBtn.enabled = false
                playPauseBtn.alpha = 0.5
                //timer.textColor = UIColor.darkGrayColor()
                playPauseBtn.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
                if secondCountdown == 0 {
                    
                    if let calls = currCall.currentCalls {
                        for call in calls {
                            if call.callState == CTCallStateConnected {
                                playVibration()
                            }
                        }
                    } else {
                        playSoundEffect("beep.wav", soundTwo: "beep.wav", loops: 2, vibration: true)
                    }
                }
                isWorktimeClockActive ? (status.text = "Work done") : (status.text = "Rest done")
                status.textColor = UIColor.yellowColor()
                status.alpha = 1
                progressFull = true
                timer.text = "00:00"

                plusOneMin.enabled = false
                plusOneMin.alpha = 0.5
                
                if autoSwitch && isStartPressed {
                    
                    autoSwitchIntervalTimer()
                    autoSwitchTimer = NSTimer.scheduledTimerWithTimeInterval(1.1,
                                                            target: self,
                                                            selector: #selector(ViewController.autoSwitchIntervalTimer),
                                                            userInfo: nil,
                                                            repeats: true)
                    
                    delay(3.0, closure: {
                        if !self.playPauseBtn.enabled {
                            self.nextBtn(self)
                            self.PlayStop(self)
                        }
                    })
                }
            }
            iteration = 0
        }
    }
    
    //MARK:
    //MARK: clock refresh
    
    // display the user set time
    func displayClock(){
        
        // get the presetTime from global.swift
        let timerController = timerManager(worktimerSetByUser: 0, resttimerSetByUser: 0)
        if isWorktimeClockActive || skipRest {
            presetTime = Double(timerController.currentTimer().worktimerSetByUser)
        } else {
            presetTime = Double(timerController.currentTimer().resttimerSetByUser)
        }

        secondCountdown = Int(presetTime)                                           // counter uses secondCountdown
        let minutes = secondCountdown / 60
        let seconds = secondCountdown - (minutes * 60)
        let timerOutlet : String = String(format: "%02d:%02d", minutes, seconds)
        timer.text = timerOutlet

        // mini label update
        let presetWorkTimeMini = Double(timerController.currentTimer().worktimerSetByUser)
        let presetRestTimeMini = Double(timerController.currentTimer().resttimerSetByUser)
        let miniWTCountdown = Int(presetWorkTimeMini)
        let miniRTCountdown = Int(presetRestTimeMini)
        let miniWorkMin = miniWTCountdown / 60
        let miniWorkSec = miniWTCountdown - (miniWorkMin * 60)
        let miniRestMin = miniRTCountdown / 60
        let miniRestSec = miniRTCountdown - (miniRestMin * 60)
        let miniWorkTimerOutlet = String(format: "W %02d:%02d", miniWorkMin, miniWorkSec)
        worktimeLabel.text = miniWorkTimerOutlet
        let miniRestTimerOutlet = String(format: "R %02d:%02d", miniRestMin, miniRestSec)
        resttimeLabel.text = miniRestTimerOutlet
    }
    
    // refresh the clock time while the clock is active (for progress bar and clock display when +1 min)
    func refreshClock(){
        
        //progress += Float (0.01 / presetTime)
        self.progressBar.setProgress(progress, animated: true)
        let minutes = secondCountdown / 60
        let seconds = secondCountdown - (minutes * 60)
        let timerOutlet : String = String(format: "%02d:%02d", minutes, seconds)
        timer.text = timerOutlet
    }
    
    func refreshCurrentDT(){
        
        if displayingDate {
            
            let date = NSDate()
            let dateOutput = NSDateFormatter()
            dateOutput.locale = NSLocale(localeIdentifier:"en_US")
            dateOutput.dateFormat = "MMMM d"
            currentDateDisplay.setTitle(dateOutput.stringFromDate(date), forState: UIControlState.Normal)
        } else {
            
            let date = NSDate()
            let dateOutput = NSDateFormatter()
            dateOutput.locale = NSLocale(localeIdentifier:"en_US")
            dateOutput.dateFormat = "EEEE"
            currentDateDisplay.setTitle(dateOutput.stringFromDate(date), forState: UIControlState.Normal)
        }
        
        if displayingAMPM {
            
            let date = NSDate()
            let timeOutput = NSDateFormatter()
            timeOutput.locale = NSLocale(localeIdentifier:"en_US")
            timeOutput.dateFormat = "h:mm a"
            currentTimeDisplay.setTitle(timeOutput.stringFromDate(date), forState: UIControlState.Normal)
        } else {
            
            let date = NSDate()
            let timeOutput = NSDateFormatter()
            timeOutput.locale = NSLocale(localeIdentifier:"en_US")
            timeOutput.dateFormat = "HH:mm"
            currentTimeDisplay.setTitle(timeOutput.stringFromDate(date), forState: UIControlState.Normal)
        }
    }
    
    //MARK:
    //MARK: playback controls
    
    @IBAction func PlayStop(sender: AnyObject) {  // should've been PlayPause for this button
       
        if secondCountdown != 0 {
           
            stopBtn.enabled = true
            stopBtn.alpha = 1
            nextBtn.enabled = true
            nextBtn.alpha = 1
            plusOneMin.enabled = true
            plusOneMin.alpha = 1
            timer.textColor = UIColor.whiteColor()
            if btnSoundEffect {
                playSoundEffect("play.wav", soundTwo: "blip.wav", loops: 0, vibration: false)
            }
            
            if !isStartPressed{
                
                playPauseBtn.setImage(UIImage(named: "pause.png"), forState: UIControlState.Normal)
                //stops the displayClock
                if myAppDelegate.displayClockTimer != nil {
                    
                    myAppDelegate.displayClockTimer!.invalidate()
                }
                
                //starts the clock
                setTimer()
                isWorktimeClockActive ? (status.text = "working") : (status.text = "resting")
                status.textColor = UIColor.cyanColor()
                status.alpha = 1.0
                isStartPressed = true
                myAppDelegate.isStartPressed = isStartPressed
                myAppDelegate.isTimerActive = true
                isClockInWorkingMode = true
                isPausing = false
                
                //stop refreshClock()
                myAppDelegate.refreshClock?.invalidate()
                
                // invalidate the pickerView
                NSNotificationCenter.defaultCenter().postNotificationName("invalidatePickerViewID", object: nil)
                
            } else {
                
                playPauseBtn.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
                
                // pause the clock
                myAppDelegate.countdownTimer!.invalidate()
                status.text = "PAUSED"
                isPausing = true
                status.textColor = UIColor.yellowColor()
                status.alpha = 1.0
                isStartPressed = false
                myAppDelegate.isStartPressed = isStartPressed
                myAppDelegate.isTimerActive = false
                
                //start refreshClock(), in case the user adjust the clock after pausing
                myAppDelegate.refreshClock = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(ViewController.refreshClock), userInfo: nil, repeats: true)
            }
        }
       
    }
    
    @IBAction func stop(sender: AnyObject) {
        
        
        if isClockInWorkingMode && secondCountdown > 0 {
            let alert = UIAlertController(title: "Stop Timer?",
                                          message: "The timer is currently running, are you sure you want to stop it?",
                                          preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { action in
                self.stopTimer()
                //NSNotificationCenter.defaultCenter().postNotificationName("validatePickerViewID", object: nil)
                isClockInWorkingMode = false
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
            }))
            self.presentViewController(alert, animated: true, completion: nil)

        } else {
            self.stopTimer()
        }
    }
    
    @IBAction func plusOneMin(sender: AnyObject) {
        
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        secondCountdown += 60
        progress = progress * Float((presetTime / (presetTime + 60)))
        presetTime += 60
        addMinCount += 1
        
        if addMinCount > 0 {
            addMinOutlet.alpha = 1
         //   if addMinCount < 10 {
         //       addMinOutlet.text = String("+ 0\(addMinCount) min")
         //   } else {
                addMinOutlet.text = String("+\(addMinCount)")
         //   }
        }
    }
    
    @IBAction func nextBtn(sender: AnyObject) {
        
        if isClockInWorkingMode && secondCountdown > 0 {
            let alert = UIAlertController(title: "Moving on?",
                                          message: "The current phase is ongoing, are you sure you want to move to the next phase?",
                                          preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { action in
                self.switchToNextPhase()
                isClockInWorkingMode = false
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            
        } else {
            self.switchToNextPhase()
        }

        
    }
    
    @IBAction func skipRestBtnAction(sender: AnyObject) {
        
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        oldStatusText = status.text!

        if skipRest {
            skipRest = false
            skipBtn.setImage(UIImage(named: "skip.png"), forState: UIControlState.Normal)
            status.text = "skip rest off"
            status.textColor = UIColor.orangeColor()
            labelDelayFunc()
        } else {
            skipRest = true
            skipBtn.setImage(UIImage(named: "skip colored.png"), forState: UIControlState.Normal)
            status.text = "skip rest on"
            status.textColor = UIColor.orangeColor()
            labelDelayFunc()
        }
    }
    
    @IBAction func autoSwitchBtnAction(sender: AnyObject) {
        
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        oldStatusText = status.text!

        if !autoSwitch {
            
            autoSwitch = true
            autoSwitchBtn.setImage(UIImage(named: "autoSwitchColored.png"), forState: UIControlState.Normal)
            status.text = "auto switch on"
            status.textColor = UIColor.orangeColor()
            labelDelayFunc()
        } else {
            
            autoSwitch = false
            autoSwitchBtn.setImage(UIImage(named: "autoSwitch.png"), forState: UIControlState.Normal)
            status.text = "auto switch off"
            status.textColor = UIColor.orangeColor()
            labelDelayFunc()
        }
    }
    
    @IBAction func volumeBarAdjusted(sender: AnyObject) {
        
        NSUserDefaults.standardUserDefaults().setFloat(volumeBar.value, forKey: "volumeBar")
    }
    
    @IBAction func currentTimeAction(sender: AnyObject) {
       
        if btnSoundEffect {
            playSoundEffect("pop.wav", soundTwo: "pop.wav", loops: 0, vibration: false)
        }
        if displayingAMPM {
           
            let date = NSDate()
            let timeOutput = NSDateFormatter()
            timeOutput.locale = NSLocale(localeIdentifier:"en_US")
            timeOutput.dateFormat = "HH:mm" // change to 24Hr format
            currentTimeDisplay.setTitle(timeOutput.stringFromDate(date), forState: UIControlState.Normal)
            displayingAMPM = false
       } else {
            
            let date = NSDate()
            let timeOutput = NSDateFormatter()
            timeOutput.locale = NSLocale(localeIdentifier:"en_US")
            timeOutput.dateFormat = "h:mm a" // back to AM/PM
            currentTimeDisplay.setTitle(timeOutput.stringFromDate(date), forState: UIControlState.Normal)
            displayingAMPM = true
        }
    }
    
    @IBAction func currentDateAction(sender: AnyObject) {
        
        if btnSoundEffect {
            playSoundEffect("pop.wav", soundTwo: "pop.wav", loops: 0, vibration: false)
        }
        
        if displayingDate {
            
            let date = NSDate()
            let dateOutput = NSDateFormatter()
            dateOutput.locale = NSLocale(localeIdentifier:"en_US")
            dateOutput.dateFormat = "EEEE"
            currentDateDisplay.setTitle(dateOutput.stringFromDate(date), forState: UIControlState.Normal)
            displayingDate = false
        } else {
            
            let date = NSDate()
            let dateOutput = NSDateFormatter()
            dateOutput.locale = NSLocale(localeIdentifier:"en_US")
            dateOutput.dateFormat = "MMMM d"
            currentDateDisplay.setTitle(dateOutput.stringFromDate(date), forState: UIControlState.Normal)
            displayingDate = true
        }
    }

    //MARK:
    //MARK: alarm sounds
    
    func playSoundEffect(soundOne: String, soundTwo: String, loops: Int, vibration: Bool) {
        
        var soundEffect = String()
        !isStartPressed ? (soundEffect = soundOne) : (soundEffect = soundTwo)
        let path = NSBundle.mainBundle().pathForResource(soundEffect, ofType:nil)!
        let url = NSURL(fileURLWithPath: path)
        
        if vibration {
            playVibration()
        }
       
        do {
            let sound = try AVAudioPlayer(contentsOfURL: url)
            audioPlayer = sound
            sound.numberOfLoops = loops
            sound.volume = volumeBar.value
            sound.play()
        } catch {
            // couldn't load file :(
        }
    }
    
    @IBAction func volumeUp(sender: AnyObject) {
        volumeBar.value += 0.1
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
    }
    
    @IBAction func volumeDown(sender: AnyObject) {
        volumeBar.value -= 0.1
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
    }
    
    //MARK:
    //MARK: Instruction View
    
    func numberOfCoachMarksForCoachMarksController(coachMarkController: CoachMarksController)
        -> Int {
            return 6
    }
    
    func coachMarksController(coachMarksController: CoachMarksController, coachMarksForIndex index: Int) -> CoachMark {
        switch(index) {
        case 0:
            return coachMarksController.coachMarkForView(self.worktimeLabel)
        case 1:
            return coachMarksController.coachMarkForView(self.resttimeLabel)
        case 2:
            return coachMarksController.coachMarkForView(self.plusOneMin)
        case 3:
            return coachMarksController.coachMarkForView(self.autoSwitchBtn)
        case 4:
            return coachMarksController.coachMarkForView(self.skipBtn)
        case 5:
            return coachMarksController.coachMarkForView(self.volumeBar)
        default:
            return coachMarksController.coachMarkForView()
        }
    }
    
    func coachMarksController(coachMarksController: CoachMarksController, coachMarkViewsForIndex index: Int, coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        
        var bodyView : CoachMarkBodyView
        var arrowView : CoachMarkArrowView?
        //var hintText = ""
        
        switch(index) {
        case 0:
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            
            coachMarkBodyView.hintLabel.text = self.workTimeText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView

        case 1:
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            
            coachMarkBodyView.hintLabel.text = self.restTimeText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView            //hintText = self.restTimeText
        case 2:
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            
            coachMarkBodyView.hintLabel.text = self.addMinText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView
           // hintText = self.addMinText
        case 3:
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            
            coachMarkBodyView.hintLabel.text = self.autoSwitchText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView
            //hintText = self.autoSwitchText
        case 4:
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            
            coachMarkBodyView.hintLabel.text = self.skipRestText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView
            //hintText = self.skipRestText
        case 5:
            
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            
            coachMarkBodyView.hintLabel.text = self.volumeControlText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView

            //hintText = self.volumeControlText
        default:
            let coachViews = coachMarksController.defaultCoachViewsWithArrow(true, arrowOrientation: coachMark.arrowOrientation)
        
            bodyView = coachViews.bodyView
            arrowView = coachViews.arrowView
        }
        
        //let coachViews = coachMarksController.defaultCoachViewsWithArrow(true, arrowOrientation: coachMark.arrowOrientation, hintText: hintText, nextText: nil)
        
        //return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
        return (bodyView: bodyView, arrowView: arrowView)
    }
    
    //MARK:
    //MARK: helper function
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func labelDelayFunc() {
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            UIView.transitionWithView(self.status, duration: 0.25, options: [.TransitionCrossDissolve], animations: {
                    if self.isStartPressed {
                        if self.isWorktimeClockActive {
                            self.status.text = "working"
                            self.status.textColor = UIColor.cyanColor()
                        } else {
                            self.status.text = "resting"
                            self.status.textColor = UIColor.cyanColor()
                        }
                    } else if self.isPausing {
                        self.status.text = "pause"
                        self.status.textColor = UIColor.yellowColor()
                    } else if self.isWorktimeClockActive {
                        self.status.text = "work mode"
                        self.status.textColor = UIColor.cyanColor()
                    } else {
                        self.status.text = "rest mode"
                        self.status.textColor = UIColor.cyanColor()
                    }
            }, completion: nil)
        }
    }
    
    func playVibration() {
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
    func stopTimer() {
        
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        
        if myAppDelegate.countdownTimer != nil {
            myAppDelegate.countdownTimer!.invalidate()
            myAppDelegate.countdownTimer = nil
        }
        
        presetTime = presetWorkTimeByUser
        secondCountdown = Int(presetTime)
        progressBar.progress = 0.0
        progress = 0.0
        iteration = 0
        displayClock()
        
        playPauseBtn.enabled = true
        playPauseBtn.alpha = 1
        playPauseBtn.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
        //playPauseBtnRing.layer.borderColor = UIColor.cyanColor().CGColor
        //playPauseBtnRing.alpha = 1
        
        stopBtn.enabled = false
        stopBtn.alpha = 0.5
        
        isWorktimeClockActive ? (status.text = "work mode") : (status.text = "rest mode")
        status.textColor = UIColor.cyanColor()
        status.alpha = 1.0
        isStartPressed = false
        myAppDelegate.isTimerActive = false
        isClockInWorkingMode = false
        
        plusOneMin.enabled = false
        plusOneMin.alpha = 0.5
        
        timer.textColor = UIColor.whiteColor()
        firstRun = true
        progressFull = false
        
        addMinCount = 0
        addMinOutlet.alpha = 0
        
        // stop refreshClock()
        myAppDelegate.refreshClock?.invalidate()
        
        // validate the pickerView
        NSNotificationCenter.defaultCenter().postNotificationName("validatePickerViewID", object: nil)
        
        if autoSwitchTimer != nil {
            autoSwitchIntervalTimerInvalid()
        }

    }
    
    func switchToNextPhase() {
        
        UIView.transitionWithView(self.timer, duration: 0.4, options: [.TransitionCrossDissolve], animations: nil, completion: nil)
        UIView.transitionWithView(self.status, duration: 0.4, options: [.TransitionFlipFromTop], animations: nil, completion: nil)
        
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        
        if isWorktimeClockActive {
            isWorktimeClockActive = false
            //self.timer.backgroundColor = UIColor(red: 0.0, green: 0.31, blue: 0.59, alpha: 0.0)
        } else {
            isWorktimeClockActive = true
            //self.timer.backgroundColor = UIColor(white: 0, alpha: 0.5)
        }
        if myAppDelegate.countdownTimer != nil { myAppDelegate.countdownTimer!.invalidate() }
        progressBar.progress = 0.0
        progress = 0.0
        iteration = 0
        displayClock()
        
        addMinCount = 0
        addMinOutlet.alpha = 0
        
        if isStartPressed {
            isStartPressed = false
            myAppDelegate.isTimerActive = false
        }
        
        playPauseBtn.enabled = true
        playPauseBtn.alpha = 1
        playPauseBtn.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
        timer.textColor = UIColor.whiteColor()
        myAppDelegate.isNewSession = true
        
        //start refreshClock(), in case the user adjust the clock after jumping to the next working phase
        myAppDelegate.refreshClock = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(ViewController.refreshClock), userInfo: nil, repeats: true)
        skipRest ? status.text = "work mode" : (isWorktimeClockActive ? (status.text = "work mode") : (status.text = "rest mode"))
        status.textColor = UIColor.cyanColor()
        status.alpha = 1.0
        
        if isWorktimeClockActive || skipRest {
            worktimeLabel.textColor = UIColor.cyanColor()
            resttimeLabel.textColor = UIColor.darkGrayColor()
        } else {
            worktimeLabel.textColor = UIColor.darkGrayColor()
            resttimeLabel.textColor = UIColor.cyanColor()
        }
        
        if autoSwitchTimer != nil {
            autoSwitchIntervalTimerInvalid()
        }

    }
    
    func autoSwitchIntervalTimer() {
    
        if autoSwitchInterval >= 0 {
            autoSwitchCtnDwnLbl.alpha = 1
            autoSwitchCtnDwnLbl.text = String(autoSwitchInterval)
            autoSwitchInterval -= 1

            if autoSwitchInterval == -1 {
                autoSwitchIntervalTimerInvalid()
            }
        }
    }
    
    func autoSwitchIntervalTimerInvalid() {
       
        autoSwitchCtnDwnLbl.text = "0"
        autoSwitchCtnDwnLbl.alpha = 0
        autoSwitchInterval = 3
        autoSwitchTimer!.invalidate()
        autoSwitchTimer = nil
    }

    
}//class end














