//
//  AppDelegate.swift
//  LE
//
//  Created by Rahil Patel on 11/12/16.
//  Copyright © 2016 Rahil. All rights reserved.
//
//  Helped by Shreyul Patel

import UIKit
import UserNotifications
import Firebase
import FirebaseMessaging
import GooglePlaces
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    var googleAPIKey = "AIzaSyB4pOS_SFVlZ78dl6rYDyzhkXWu7nrASk8"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FIRApp.configure()
        GMSPlacesClient.provideAPIKey(googleAPIKey)
        GMSServices.provideAPIKey(googleAPIKey)
        
        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
            
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
        }
        if let token = FIRInstanceID.instanceID().token() {
            AppData.token = token
        }
        clearBadgeNumber()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("App became active")
        clearBadgeNumber()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
        let aps = userInfo["aps"] as! [AnyHashable:Any]
        UIApplication.shared.applicationIconBadgeNumber = (aps["badge"] as! Int) + 1
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let tkn = FIRInstanceID.instanceID().token() {
            print("-----------------------------\n\(tkn)\n--------------------------------")
            AppData.token = tkn
        }
    }
    
    private func clearBadgeNumber() {
        if let token = FIRInstanceID.instanceID().token() {
            if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
                let path = "Users/User: \(currentUserID)/pushTokens/\(token)"
                let ref = FIRDatabase.database().reference(withPath: path)
                ref.setValue(0)
                
                UIApplication.shared.applicationIconBadgeNumber = 0

            }
            else {
                //User not logged in
            }
        }
        else {
            //no device token for this device is registered
        }
    }
}

