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
    let myAppDelegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
    let playStop = UIButton()
    var isWorktimeClockActive = true
    var skipRest = false
    var displayingAMPM = true
    var displayingDate = true
    var refreshCurrentDateAndTime = Foundation.Timer()
    var audioPlayer = AVAudioPlayer()
    var addMinCount = 0
    var autoSwitch = false
    var oldStatusText = ""
    var isPausing = false
    var btnSoundEffect = true
    var screenAlwaysLit = false
    let currCall = CTCallCenter()
    var autoSwitchInterval = 4
    var autoSwitchTimer : Foundation.Timer?
    
    // instruction view
    let pointOfInterest = UIView()
    var coachMarksController: CoachMarksController?
    let workTimeText = "Hi there! Quick walk-through? \nTimer can be operated in 2 modes:  \nWORKING 💪 and RESTING 😪. \n\nThis indicates your work duration, which can be changed later"
    let restTimeText = "This is the rest-mode duration"
    let addMinText = "In case you are running short on time but want to keep going, this adds minutes on the go!"
    let autoSwitchText = "Switching this on will automatically transition between work & rest. Sweet!"
    let skipRestText = "In case you want to skip the rest all together, enable this will keep your timer in working mode."
    let volumeControlText = "Button and the alert sound volume control. \nYou can turn off button sound effect in Settings ⚙. \n\n🎉That's it!! Enjoy!!!😁"

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
        skipView.setTitle("Skip", for: UIControlState())
        self.coachMarksController?.skipView = skipView
        self.coachMarksController?.overlayBackgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.91)
        
        // my timer presets
        displayClock()
        stopBtn.isEnabled = false
        stopBtn.alpha = 0.5
        progressBar.progress = 0.0
        playPauseBtn.setImage(UIImage(named: "play.png"), for: UIControlState())
        playPauseBtn.alpha = 1.0
        plusOneMin.isEnabled = false
        plusOneMin.alpha = 0.5
        nextBtn.isEnabled = true
        status.text = "work mode"
        status.textColor = UIColor.white
        status.alpha = 1.0
        volumeBar.value = UserDefaults.standard.float(forKey: "volumeBar")

        let date = Date()
        let dateOutput = DateFormatter()
        dateOutput.locale = Locale(identifier:"en_US")
        dateOutput.dateFormat = "MMMM d"
        currentDateDisplay.setTitle(dateOutput.string(from: date), for: UIControlState())
        let timeOutput = DateFormatter()
        timeOutput.locale = Locale(identifier:"en_US")
        timeOutput.dateFormat = "h:mm a"
        currentTimeDisplay.setTitle(timeOutput.string(from: date), for: UIControlState())
        
        // refreshing the Date/Time display
        refreshCurrentDateAndTime = Foundation.Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.refreshCurrentDT), userInfo: nil, repeats: true)
        
        // notification center for receiving if user has slide to the right menu
        NotificationCenter.default.addObserver(self,
                                         selector: #selector(ViewController.userAdjustClock(_:)),
                                         name: NSNotification.Name(rawValue: "userAdjustClockID"),
                                         object: nil)
        
        NotificationCenter.default.addObserver(self,
                                         selector: #selector(ViewController.rightVCDidDisappear(_:)),
                                         name: NSNotification.Name(rawValue: "rightVCDisappearID"),
                                         object: nil)
        
        NotificationCenter.default.addObserver(self,
                                         selector: #selector(ViewController.comebackFromSuspendidState(_:)),
                                         name: NSNotification.Name(rawValue: "comebackFromSuspendidStateID"),
                                         object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // first time running, set state to has launched
        let hasLaunched =  UserDefaults.standard.bool(forKey: "HasLaunched")
        if !hasLaunched {
            self.coachMarksController?.startOn(self)
            UserDefaults.standard.set(true, forKey: "HasLaunched")
        }
        
        autoSwitch = UserDefaults.standard.bool(forKey: "autoSwitchState")
        autoSwitch ? autoSwitchBtn.setImage(UIImage(named: "autoSwitchColored.png"), for: UIControlState()) :
                     autoSwitchBtn.setImage(UIImage(named: "autoSwitch.png"), for: UIControlState())
        btnSoundEffect = UserDefaults.standard.bool(forKey: "btnSoundSwitchState")
        UIApplication.shared.isIdleTimerDisabled = UserDefaults.standard.bool(forKey: "screenLitSwitchState")
    }
    
    func comebackFromSuspendidState(_ notification: Notification) {
        let timeSpotWhenSuspended = myAppDelegate.userDefaults.value(forKey: "TimeSpot")
        if timeSpotWhenSuspended != nil && isStartPressed == true {
            let currentTime = Date()
            let timeInterval: Double = currentTime.timeIntervalSince(timeSpotWhenSuspended as! Date);
            if secondCountdown < Int(timeInterval){
                secondCountdown = 0
                progress = 1
            } else {
                secondCountdown -= Int(timeInterval)
                progress += Float (timeInterval / presetTime)
            }
        }
    }
    
    func userAdjustClock(_ notification: Notification){
        myAppDelegate.displayClockTimer = Foundation.Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.displayClock), userInfo: nil, repeats: true)

    }
    
    func rightVCDidDisappear(_ notification: Notification){
        if myAppDelegate.displayClockTimer != nil{
            myAppDelegate.displayClockTimer!.invalidate()
        }
    }
  
    //MARK:
    //MARK: Timer setup
    func setTimer() {
        myAppDelegate.countdownTimer = Foundation.Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.timerRun), userInfo: nil, repeats: true)
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
                playPauseBtn.isEnabled = false
                playPauseBtn.alpha = 0.5
                //timer.textColor = UIColor.darkGrayColor()
                playPauseBtn.setImage(UIImage(named: "play.png"), for: UIControlState())
                if secondCountdown == 0 {
                    if let calls = currCall.currentCalls {
                        for call in calls {
                            if call.callState == CTCallStateConnected {
                                playVibration()
                            }
                        }
                    } else {
                        playSoundEffect("chime.mp3", soundTwo: "chime.mp3", loops: 1, vibration: true)
                    }
                }
                isWorktimeClockActive ? (status.text = "Work done") : (status.text = "Rest done")
                status.textColor = UIColor.yellow
                status.alpha = 1
                progressFull = true
                timer.text = "00:00"
                plusOneMin.isEnabled = false
                plusOneMin.alpha = 0.5
                
                if autoSwitch && isStartPressed {
                    autoSwitchIntervalTimer()
                    autoSwitchTimer = Foundation.Timer.scheduledTimer(timeInterval: 1.1,
                                                            target: self,
                                                            selector: #selector(ViewController.autoSwitchIntervalTimer),
                                                            userInfo: nil,
                                                            repeats: true)
                    delay(4.0, closure: {
                        if !self.playPauseBtn.isEnabled {
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
            let date = Date()
            let dateOutput = DateFormatter()
            dateOutput.locale = Locale(identifier:"en_US")
            dateOutput.dateFormat = "MMMM d"
            currentDateDisplay.setTitle(dateOutput.string(from: date), for: UIControlState())
        } else {
            let date = Date()
            let dateOutput = DateFormatter()
            dateOutput.locale = Locale(identifier:"en_US")
            dateOutput.dateFormat = "EEEE"
            currentDateDisplay.setTitle(dateOutput.string(from: date), for: UIControlState())
        }
        
        if displayingAMPM {
            let date = Date()
            let timeOutput = DateFormatter()
            timeOutput.locale = Locale(identifier:"en_US")
            timeOutput.dateFormat = "h:mm a"
            currentTimeDisplay.setTitle(timeOutput.string(from: date), for: UIControlState())
        } else {
            let date = Date()
            let timeOutput = DateFormatter()
            timeOutput.locale = Locale(identifier:"en_US")
            timeOutput.dateFormat = "HH:mm"
            currentTimeDisplay.setTitle(timeOutput.string(from: date), for: UIControlState())
        }
    }
    
    //MARK:
    //MARK: playback controls
    @IBAction func PlayStop(_ sender: AnyObject) {  // should've been PlayPause for this button
        if secondCountdown != 0 {
            stopBtn.isEnabled = true
            stopBtn.alpha = 1
            nextBtn.isEnabled = true
            nextBtn.alpha = 1
            plusOneMin.isEnabled = true
            plusOneMin.alpha = 1
            timer.textColor = UIColor.white
            if btnSoundEffect {
                playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
            }
            
            if !isStartPressed{
                playPauseBtn.setImage(UIImage(named: "pause.png"), for: UIControlState())
                //stops the displayClock
                if myAppDelegate.displayClockTimer != nil {
                    
                    myAppDelegate.displayClockTimer!.invalidate()
                }
                //starts the clock
                setTimer()
                isWorktimeClockActive ? (status.text = "working") : (status.text = "resting")
                status.textColor = UIColor.cyan
                status.alpha = 1.0
                isStartPressed = true
                myAppDelegate.isStartPressed = isStartPressed
                myAppDelegate.isTimerActive = true
                isClockInWorkingMode = true
                isPausing = false
                
                //stop refreshClock()
                myAppDelegate.refreshClock?.invalidate()
                // invalidate the pickerView
                NotificationCenter.default.post(name: Notification.Name(rawValue: "invalidatePickerViewID"), object: nil)
                
            } else {
                playPauseBtn.setImage(UIImage(named: "play.png"), for: UIControlState())
                
                // pause the clock
                myAppDelegate.countdownTimer!.invalidate()
                status.text = "PAUSED"
                isPausing = true
                status.textColor = UIColor.yellow
                status.alpha = 1.0
                isStartPressed = false
                myAppDelegate.isStartPressed = isStartPressed
                myAppDelegate.isTimerActive = false
                
                //start refreshClock(), in case the user adjust the clock after pausing
                myAppDelegate.refreshClock = Foundation.Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.refreshClock), userInfo: nil, repeats: true)
            }
        }
       
    }
    
    @IBAction func stop(_ sender: AnyObject) {
        if isClockInWorkingMode && secondCountdown > 0 {
            let alert = UIAlertController(title: "Stop Timer?",
                                          message: "The timer is currently running, are you sure you want to stop it?",
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: { action in
                self.stopTimer()
                //NSNotificationCenter.defaultCenter().postNotificationName("validatePickerViewID", object: nil)
                isClockInWorkingMode = false
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { action in
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.stopTimer()
        }
    }
    
    @IBAction func plusOneMin(_ sender: AnyObject) {
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        secondCountdown += 60
        progress = progress * Float((presetTime / (presetTime + 60)))
        presetTime += 60
        addMinCount += 1
        
        if addMinCount > 0 {
            addMinOutlet.alpha = 1
            addMinOutlet.text = String("+\(addMinCount)")
        }
    }
    
    @IBAction func nextBtn(_ sender: AnyObject) {
        if isClockInWorkingMode && secondCountdown > 0 {
            let alert = UIAlertController(title: "Moving on?",
                                          message: "The current phase is ongoing, are you sure you want to move to the next phase?",
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: { action in
                self.switchToNextPhase()
                isClockInWorkingMode = false
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { action in
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.switchToNextPhase()
        }
    }
    
    @IBAction func skipRestBtnAction(_ sender: AnyObject) {
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        oldStatusText = status.text!
        if skipRest {
            skipRest = false
            skipBtn.setImage(UIImage(named: "skip.png"), for: UIControlState())
            status.text = "skip rest off"
            status.textColor = UIColor.yellow
            labelDelayFunc()
        } else {
            skipRest = true
            skipBtn.setImage(UIImage(named: "skip colored.png"), for: UIControlState())
            status.text = "skip rest on"
            status.textColor = UIColor.yellow
            labelDelayFunc()
        }
    }
    
    @IBAction func autoSwitchBtnAction(_ sender: AnyObject) {
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        oldStatusText = status.text!

        if !autoSwitch {
            autoSwitch = true
            UserDefaults.standard.set(true, forKey: "autoSwitchState")
            autoSwitchBtn.setImage(UIImage(named: "autoSwitchColored.png"), for: UIControlState())
            status.text = "auto switch on"
            status.textColor = UIColor.yellow
            labelDelayFunc()
        } else {
            autoSwitch = false
            UserDefaults.standard.set(false, forKey: "autoSwitchState")
            autoSwitchBtn.setImage(UIImage(named: "autoSwitch.png"), for: UIControlState())
            status.text = "auto switch off"
            status.textColor = UIColor.yellow
            labelDelayFunc()
        }
    }
    
    @IBAction func volumeBarAdjusted(_ sender: AnyObject) {
        UserDefaults.standard.set(volumeBar.value, forKey: "volumeBar")
    }
    
    @IBAction func currentTimeAction(_ sender: AnyObject) {
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        if displayingAMPM {
            let date = Date()
            let timeOutput = DateFormatter()
            timeOutput.locale = Locale(identifier:"en_US")
            timeOutput.dateFormat = "HH:mm" // change to 24Hr format
            currentTimeDisplay.setTitle(timeOutput.string(from: date), for: UIControlState())
            displayingAMPM = false
       } else {
            let date = Date()
            let timeOutput = DateFormatter()
            timeOutput.locale = Locale(identifier:"en_US")
            timeOutput.dateFormat = "h:mm a" // back to AM/PM
            currentTimeDisplay.setTitle(timeOutput.string(from: date), for: UIControlState())
            displayingAMPM = true
        }
    }
    
    @IBAction func currentDateAction(_ sender: AnyObject) {
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        
        if displayingDate {
            let date = Date()
            let dateOutput = DateFormatter()
            dateOutput.locale = Locale(identifier:"en_US")
            dateOutput.dateFormat = "EEEE"
            currentDateDisplay.setTitle(dateOutput.string(from: date), for: UIControlState())
            displayingDate = false
        } else {
            let date = Date()
            let dateOutput = DateFormatter()
            dateOutput.locale = Locale(identifier:"en_US")
            dateOutput.dateFormat = "MMMM d"
            currentDateDisplay.setTitle(dateOutput.string(from: date), for: UIControlState())
            displayingDate = true
        }
    }

    //MARK:
    //MARK: alarm sounds
    func playSoundEffect(_ soundOne: String, soundTwo: String, loops: Int, vibration: Bool) {
        var soundEffect = String()
        !isStartPressed ? (soundEffect = soundOne) : (soundEffect = soundTwo)
        let path = Bundle.main.path(forResource: soundEffect, ofType:nil)!
        let url = URL(fileURLWithPath: path)
        
        if vibration {
            playVibration()
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
            let sound = try AVAudioPlayer(contentsOf: url)
            audioPlayer = sound
            sound.numberOfLoops = loops
            sound.volume = volumeBar.value
            sound.play()
        } catch {
            // couldn't load file :(
        }
    }
    
    @IBAction func volumeUp(_ sender: AnyObject) {
        volumeBar.value += 0.1
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
    }
    
    @IBAction func volumeDown(_ sender: AnyObject) {
        volumeBar.value -= 0.1
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
    }
    
    //MARK:
    //MARK: Instruction View
    func numberOfCoachMarksForCoachMarksController(_ coachMarkController: CoachMarksController)
        -> Int {
            return 6
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarksForIndex index: Int) -> CoachMark {
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
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsForIndex index: Int, coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        var bodyView : CoachMarkBodyView
        var arrowView : CoachMarkArrowView?
        
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
            arrowView = coachMarkArrowView
            
        case 2:
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            coachMarkBodyView.hintLabel.text = self.addMinText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView
            
        case 3:
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            coachMarkBodyView.hintLabel.text = self.autoSwitchText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView
            
        case 4:
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            coachMarkBodyView.hintLabel.text = self.skipRestText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView
            
        case 5:
            let coachMarkBodyView = TransparentCoachMarkBodyView()
            var coachMarkArrowView: TransparentCoachMarkArrowView? = nil
            coachMarkBodyView.hintLabel.text = self.volumeControlText
            
            if let arrowOrientation = coachMark.arrowOrientation {
                coachMarkArrowView = TransparentCoachMarkArrowView(orientation: arrowOrientation)
            }
            bodyView = coachMarkBodyView
            arrowView = coachMarkArrowView
            
        default:
            let coachViews = coachMarksController.defaultCoachViewsWithArrow(true, arrowOrientation: coachMark.arrowOrientation)
            bodyView = coachViews.bodyView
            arrowView = coachViews.arrowView
        }
        return (bodyView: bodyView, arrowView: arrowView)
    }
    
    //MARK:
    //MARK: helper function
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    func labelDelayFunc() {
        let time = DispatchTime.now() + Double(1 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            UIView.transition(with: self.status, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                    if self.isStartPressed {
                        if self.isWorktimeClockActive {
                            self.status.text = "working"
                            self.status.textColor = UIColor.cyan
                        } else {
                            self.status.text = "resting"
                            self.status.textColor = UIColor.cyan
                        }
                    } else if self.isPausing {
                        self.status.text = "pause"
                        self.status.textColor = UIColor.yellow
                    } else if self.isWorktimeClockActive {
                        self.status.text = "work mode"
                        self.status.textColor = UIColor.white
                    } else {
                        self.status.text = "rest mode"
                        self.status.textColor = UIColor.white
                    }
            }, completion: nil)
        }
    }
    
    func playVibration() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        let time = DispatchTime.now() + Double(1 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
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
        playPauseBtn.isEnabled = true
        playPauseBtn.alpha = 1
        playPauseBtn.setImage(UIImage(named: "play.png"), for: UIControlState())
        stopBtn.isEnabled = false
        stopBtn.alpha = 0.5
        isWorktimeClockActive ? (status.text = "work mode") : (status.text = "rest mode")
        status.textColor = UIColor.white
        status.alpha = 1.0
        isStartPressed = false
        myAppDelegate.isTimerActive = false
        isClockInWorkingMode = false
        plusOneMin.isEnabled = false
        plusOneMin.alpha = 0.5
        timer.textColor = UIColor.white
        firstRun = true
        progressFull = false
        addMinCount = 0
        addMinOutlet.alpha = 0
        
        // stop refreshClock()
        myAppDelegate.refreshClock?.invalidate()
        
        // validate the pickerView
        NotificationCenter.default.post(name: Notification.Name(rawValue: "validatePickerViewID"), object: nil)
        if autoSwitchTimer != nil {
            autoSwitchIntervalTimerInvalid()
        }
    }
    
    func switchToNextPhase() {
        UIView.transition(with: self.timer, duration: 0.15, options: [.transitionCrossDissolve], animations: nil, completion: nil)
        UIView.transition(with: self.status, duration: 0.3, options: [.transitionCrossDissolve], animations: nil, completion: nil)
        
        if btnSoundEffect {
            playSoundEffect("btn.wav", soundTwo: "btn.wav", loops: 0, vibration: false)
        }
        
        if isWorktimeClockActive {
            isWorktimeClockActive = false
        } else {
            isWorktimeClockActive = true
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
        
        playPauseBtn.isEnabled = true
        playPauseBtn.alpha = 1
        playPauseBtn.setImage(UIImage(named: "play.png"), for: UIControlState())
        timer.textColor = UIColor.white
        myAppDelegate.isNewSession = true
        
        //start refreshClock(), in case the user adjust the clock after jumping to the next working phase
        myAppDelegate.refreshClock = Foundation.Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.refreshClock), userInfo: nil, repeats: true)
        skipRest ? status.text = "work mode" : (isWorktimeClockActive ? (status.text = "work mode") : (status.text = "rest mode"))
        status.textColor = UIColor.white
        status.alpha = 1.0
        
        if isWorktimeClockActive || skipRest {
            worktimeLabel.textColor = UIColor.cyan
            resttimeLabel.textColor = UIColor.darkGray
        } else {
            worktimeLabel.textColor = UIColor.darkGray
            resttimeLabel.textColor = UIColor.cyan
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
        autoSwitchInterval = 4
        autoSwitchTimer?.invalidate()
        autoSwitchTimer = nil
    }
    
}//class end
