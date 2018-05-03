//
//  AppDelegate.swift
//  RuleIt
//
//  Created by Qin, Charles on 3/30/16.
//  Copyright © 2016 RuleIt Inc. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics


protocol Foregrounder {
    func resumeFromBackground(_ appDelegate : AppDelegate)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    //static let sharedInstance = AppDelegate()
    //private init() {} //This prevents others from using the default '()' initializer for this class.

    
    var window: UIWindow?
    var foregrounder: Foregrounder?
    var countdownTimer: Foundation.Timer? = Foundation.Timer()
    var displayClockTimer : Foundation.Timer? = Foundation.Timer()
    var refreshClock : Foundation.Timer? = Foundation.Timer()
    var workTimeValue : Int = 0
    var restTimeValue : Int = 0
    var timeleft: Double = 0
    var isTimerActive: Bool = false
    let userDefaults = UserDefaults.standard
    var autoSwitch = false
    var isStartPressed = false
    var isNewSession = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // increment app run counter for in app review
        InAppReivew().incrementAppRuns()
        
        if UserDefaults.standard.object(forKey: "workTime") == nil {
            workTimeValue = 30
        } else {
            workTimeValue = UserDefaults.standard.object(forKey: "workTime") as! Int
        }
        
        if UserDefaults.standard.object(forKey: "restTime") == nil {
            restTimeValue = 10
        } else {
            restTimeValue = UserDefaults.standard.object(forKey: "restTime") as! Int
        }
        
        if UserDefaults.standard.object(forKey: "btnSoundSwitchState") == nil {
            UserDefaults.standard.set(true, forKey: "btnSoundSwitchState")
        }
        
        if UserDefaults.standard.object(forKey: "autoSwitchState") == nil {
            UserDefaults.standard.set(true, forKey: "autoSwitchState")
        }
        
        if UserDefaults.standard.object(forKey: "screenLitSwitchState") == nil {
            UserDefaults.standard.set(true, forKey: "screenLitSwitchState")
        }
        
        if UserDefaults.standard.object(forKey: "volumeBar") == nil {
            UserDefaults.standard.set(0.5, forKey: "volumeBar")
        }
        
        let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        UIApplication.shared.statusBarStyle = .lightContent
        Thread.sleep(forTimeInterval: 1.2);
        
        Fabric.with([Crashlytics.self])
        
        for family: String in UIFont.familyNames
        {
            print("\(family)")
            for names: String in UIFont.fontNames(forFamilyName: family)
            {
                print("== \(names) haha")
            }
        }

        return true ///

    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        let suspendedTimeSpot = Date()
        userDefaults.setValue(suspendedTimeSpot, forKey: "TimeSpot")
        
        if isTimerActive && isStartPressed && timeleft != 0 && timeleft != 1{
      
            let notification = UILocalNotification()
            notification.fireDate = Date(timeIntervalSinceNow: timeleft)
            notification.alertBody = "Times up! Respond to start next phase"
            notification.soundName = "complete.wav"
            UIApplication.shared.scheduleLocalNotification(notification)
            //isNewSession = false
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        UIApplication.shared.cancelAllLocalNotifications()
        
        foregrounder?.resumeFromBackground(self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "comebackFromSuspendidStateID"), object: nil)

    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.ruleit.RuleIt" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "RuleIt", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

